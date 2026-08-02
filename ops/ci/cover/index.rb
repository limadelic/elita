require 'pathname'
require_relative 'template'

module Index
  def self.generate(prefix)
    data = parse_coverage
    modules = filter_sort(data[:modules], find_pages)
    grouped = group_by_folder(modules, build_source_map)
    render_html(grouped, data, modules, prefix)
  end

  def self.render_html(grouped, data, modules, prefix)
    zeros = count_zeros(modules)
    dropped = data[:original_count] - modules.length
    html = Template.render(grouped, data[:total], modules.length, zeros, dropped)
    File.write("site/#{prefix}cover/index.html", html)
  end

  def self.parse_coverage
    modules = []
    total = 0.0
    load_data(modules) { |t| total = t } if file_exists?
    { modules: modules, total: total, original_count: modules.length }
  end

  def self.load_data(modules)
    File.readlines('/tmp/cover_output.txt').each { |line| handle(line, modules) { |t| yield t } }
  end

  def self.handle(line, modules)
    data = safe_parse(line)
    process_data(data, modules) { |t| yield t } if data
  end

  def self.process_data(data, modules)
    if data[:name] == 'Total'
      yield(data[:pct])
    else
      modules << data
    end
  end

  def self.safe_parse(line)
    extract_from(line.strip)
  rescue ArgumentError
    nil
  end

  def self.extract_from(line)
    return unless should_process(line)

    parts = split_line(line)
    parse_data(parts)
  end

  def self.split_line(line)
    line.split('|').map(&:strip)
  end

  def self.should_process(line)
    line.start_with?('|') && line.include?('%')
  end

  def self.parse_data(parts)
    build_coverage_data(parts) if parts.length >= 3
  end

  def self.build_coverage_data(parts)
    pct_str = parts[1].chomp('%')
    name = parts[2].to_s.strip
    !name.empty? ? { name: name, pct: Float(pct_str) } : nil
  end

  def self.find_pages
    dir = Pathname.new('apps/elita/cover')
    dir.exist? ? collect_modules(dir) : Set.new
  end

  def self.collect_modules(dir)
    dir.glob('Elixir.*.html').each_with_object(Set.new) do |f, set|
      set.add(module_name(f.basename.to_s))
    end
  end

  def self.filter_sort(modules, available)
    select_available(modules, available).sort_by { |m| m[:pct] }
  end

  def self.select_available(modules, available)
    modules.select { |m| available.include?(m[:name]) }
  end

  def self.count_zeros(modules)
    modules.count { |m| m[:pct].zero? }
  end

  def self.file_exists?
    File.exist?('/tmp/cover_output.txt')
  end

  def self.module_name(filename)
    filename.sub(/^Elixir\./, '').sub(/\.html$/, '')
  end

  def self.build_source_map
    map = {}
    scan_source_dir('apps/el/lib', map)
    scan_source_dir('apps/elita/lib', map)
    map
  end

  def self.scan_source_dir(dir, map)
    Pathname.new(dir).glob('**/*.ex').each do |file|
      extract_modules_from_file(file, map)
    end
  end

  def self.extract_modules_from_file(file, map)
    folder = File.dirname(file.to_s).sub(/^\.\//, '')
    content = File.read(file)
    process_defmodules(content, folder, map)
  rescue StandardError
    nil
  end

  def self.process_defmodules(content, folder, map)
    content.split("\n").grep(/defmodule /).each { |line| store_module(line, folder, map) }
  end

  def self.store_module(line, folder, map)
    match = line.match(/defmodule\s+([\w.]+)\s+do/)
    return unless match

    map[match[1]] = folder
  end

  def self.group_by_folder(modules, source_map)
    groups = partition_by_folder(modules, source_map)
    sort_groups(groups)
  end

  def self.partition_by_folder(modules, source_map)
    modules.group_by { |m| resolve_folder(m, source_map) }
  end

  def self.resolve_folder(m, source_map)
    source_map[m[:name]] || :unmapped
  end

  def self.sort_groups(groups)
    mapped = sort_mapped_groups(groups.except(:unmapped))
    add_unmapped_group(mapped, groups[:unmapped])
  end

  def self.sort_mapped_groups(groups)
    sort_folders(groups).map { |folder, mods| [folder, sort_by_pct(mods)] }
  end

  def self.sort_folders(groups)
    groups.sort_by { |f, _| f }
  end

  def self.add_unmapped_group(mapped, unmapped)
    return mapped unless unmapped

    mapped + [['(unmapped)', sort_by_pct(unmapped)]]
  end

  def self.sort_by_pct(mods)
    mods.sort_by { |m| m[:pct] }
  end
end
