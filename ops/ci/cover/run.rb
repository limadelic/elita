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
    ensure_dirs
    copy_modules_for_app('el')
    copy_modules_for_app('elita')
  end

  def self.ensure_dirs
    FileUtils.mkdir_p('apps/el/cover')
    FileUtils.mkdir_p('apps/elita/cover')
  end

  def self.copy_modules_for_app(app_name)
    modules = list_modules_for_app(app_name)
    modules.each { |name| copy_file(name, app_name) }
  end

  def self.copy_file(name, app_name)
    src = "cover/#{name}.html"
    dst = Pathname.new("apps/#{app_name}/cover").join("#{name}.html")
    FileUtils.cp(src, dst) if File.exist?(src)
  end

  def self.list_modules_for_app(app_name)
    path = Pathname.new("_build/test/lib/#{app_name}/ebin")
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
