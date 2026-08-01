#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'

module Run
  def self.coverage
    return if recursing?

    run_cmd('cd apps/elita && mix test --cover')
    run_cmd('cd apps/el && mix test --cover')
    run_cmd('cd apps/specs && mix test --cover')
    ignore_fail('mix test.coverage')
    copy_html
  end

  def self.recursing?
    ENV['MIX_RECURSING'] == 'true'
  end

  def self.run_cmd(cmd)
    system(cmd) || raise("command failed: #{cmd}")
  end

  def self.ignore_fail(cmd)
    system(cmd)
  end

  def self.copy_html
    modules = list_modules
    ensure_dir
    copy_files(modules)
  end

  def self.ensure_dir
    FileUtils.mkdir_p('apps/elita/cover')
  end

  def self.copy_files(modules)
    modules.each { |name| copy_file(name) }
  end

  def self.copy_file(name)
    src = "cover/#{name}.html"
    dst = Pathname.new('apps/elita/cover').join("#{name}.html")
    FileUtils.cp(src, dst) if File.exist?(src)
  end

  def self.list_modules
    path = Pathname.new('_build/test/lib/elita/ebin')
    return [] unless path.exist?

    extract_names(path.glob('*.beam'))
  end

  def self.extract_names(files)
    files.map { |f| strip_beam_ext(f.basename.to_s) }.sort
  end

  def self.strip_beam_ext(name)
    name.sub(/\.beam$/, '')
  end
end

Run.coverage if __FILE__ == $PROGRAM_NAME
