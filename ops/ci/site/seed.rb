#!/usr/bin/env ruby

require 'fileutils'

module Seed
  BASE_URL = 'https://limadelic.github.io/elita'.freeze
  FILES = %w[report.html cukes.html cukes.json lint.json credo.html index.html].freeze

  def self.run
    FileUtils.mkdir_p('site')
    seed_root
    seed_branches
    seed_prs
  end

  def self.seed_root
    FILES.each { |file| fetch("#{BASE_URL}/#{file}", "site/#{file}") }
  end

  def self.seed_branches
    branches = fetch_branch_names
    seed_directory_set(branches, '')
  end

  def self.seed_prs
    prs = `gh pr list --state open --json number --jq '.[].number'`.split("\n")
    seed_directory_set(prs, '')
  end

  def self.seed_directory_set(dirs, _prefix)
    dirs.each { |dir| seed_single_dir(dir) }
  end

  def self.seed_single_dir(dir)
    FileUtils.mkdir_p("site/#{dir}")
    seed_files(dir)
  end

  def self.seed_files(path)
    FILES.each { |file| fetch("#{BASE_URL}/#{path}/#{file}", "site/#{path}/#{file}") }
  end

  def self.fetch_branch_names
    `git branch -r | sed 's/^[[:space:]]*origin\\///' | grep -v '^HEAD' | sort -u`.split("\n")
  end

  def self.fetch(url, dest)
    system("curl -sfL '#{url}' -o '#{dest}' || true")
  end
end

Seed.run if __FILE__ == $PROGRAM_NAME
