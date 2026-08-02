require 'pathname'
require 'json'
require_relative 'template'

module Index
  def self.generate(prefix)
    data = parse_coverage
    modules = filter_sort(data[:modules], find_pages)
    tree = build_tree(modules, build_source_map)
    tree = collapse_single_children(tree)
    render_html(tree, data, modules, prefix)
  end

  def self.render_html(tree, data, modules, prefix)
    zeros = count_zeros(modules)
    dropped = data[:original_count] - modules.length
    html = Template.render(tree, data[:total], modules.length, zeros, dropped)
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
    pages = Set.new
    %w[apps/el/cover apps/elita/cover].each { |path| pages.merge(modules_from_dir(path)) }
    pages
  end

  def self.modules_from_dir(dir_path)
    dir = Pathname.new(dir_path)
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

  def self.build_tree(modules, source_map)
    root = { name: 'root', type: 'folder', children: {}, modules: [] }
    modules.each { |m| add_module_to_tree(root, m, source_map) }
    root
  end

  def self.add_module_to_tree(root, module_data, source_map)
    folder = resolve_folder(module_data, source_map)
    return if folder == :unmapped

    normalized = normalize_folder_path(folder)
    ensure_folder_path(root, normalized)[:modules] << module_data
  end

  def self.normalize_folder_path(folder_path)
    folder_path.sub(%r{^apps/}, '')
  end

  def self.ensure_folder_path(root, folder_path)
    parts = folder_path.split('/')
    node = root
    parts.each { |part| node = ensure_folder(node, part) }
    node
  end

  def self.ensure_folder(node, part)
    node[:children][part] ||= { name: part, type: 'folder', children: {}, modules: [] }
    node[:children][part]
  end

  def self.resolve_folder(m, source_map)
    source_map[m[:name]] || :unmapped
  end

  def self.collapse_single_children(node)
    collapsed = node.dup
    collapsed[:children] = node[:children].transform_values { |child| collapse_single_children(child) }
    collapse_chains(collapsed)
  end

  def self.collapse_chains(collapsed)
    while should_collapse?(collapsed)
      merged = merge_single_child(collapsed)
      collapsed = merged
    end
    collapsed
  end

  def self.should_collapse?(node)
    empty?(node) && one_child?(node)
  end

  def self.empty?(node)
    node[:modules].empty?
  end

  def self.one_child?(node)
    node[:children].length == 1 && node[:name] != 'root'
  end

  def self.merge_single_child(node)
    only_child_key = node[:children].keys.first
    only_child = node[:children][only_child_key]
    node[:name] = collapse_path(node[:name], only_child[:name])
    node[:children] = only_child[:children]
    node[:modules] = only_child[:modules]
    node
  end

  def self.collapse_path(parent_name, child_name)
    return child_name if parent_name == 'root'

    "#{parent_name}/#{child_name}"
  end
end
