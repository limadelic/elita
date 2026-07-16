#!/usr/bin/env ruby

require 'json'
require 'fileutils'

module Badges
  def self.run
    prefix = compute_prefix
    FileUtils.mkdir_p("site/#{prefix}")
    lint_badges(prefix)
    cukes_badges(prefix)
  end

  def self.compute_prefix
    branch = ENV['BRANCH'].sub(%r{/merge$}, '')
    return '' if branch == 'main' || branch == 'test'

    repo = ENV['GITHUB_REPOSITORY']
    cmd = %Q{gh api repos/#{repo}/pulls -q '.[] | select(.head.ref=="#{branch}") | .number' | head -1}
    pr_num = `#{cmd}`.strip
    return "#{pr_num}/" unless pr_num.empty?

    "#{branch}/"
  end

  def self.lint_badges(prefix)
    return unless File.exist?('/tmp/credo.json')

    credo = JSON.parse(File.read('/tmp/credo.json'))
    issue_count = credo['issues'].length
    color, message = lint_color_message(issue_count)
    json = JSON.generate(badge('credo', message, color))
    File.write("site/#{prefix}/lint.json", json)
  end

  def self.cukes_badges(prefix)
    return unless File.exist?('reports/cucumber.json')

    data = JSON.parse(File.read('reports/cucumber.json'))
    scenarios = data.flat_map { |f| f['elements'] || [] }
    write_cukes_files(prefix, scenarios)
  end

  def self.write_cukes_files(prefix, scenarios)
    passed = count_passed(scenarios)
    message, color = cukes_color_message(passed, scenarios.length)
    File.write("site/#{prefix}/cukes.json", JSON.generate(badge('cukes', message, color, 'cucumber')))
    File.write("site/#{prefix}/cukes_badge.txt", "cukes: #{message}")
  end

  def self.count_passed(scenarios)
    scenarios.count { |sc| (sc['steps'] || []).all? { |s| s.dig('result', 'status') == 'passed' } }
  end

  def self.badge(label, message, color, named_logo = nil)
    badge = {
      schemaVersion: 1,
      label: label,
      message: message,
      color: color,
      labelColor: '173647'
    }
    badge[:namedLogo] = named_logo
    badge[:logoColor] = 'white' if named_logo
    badge
  end

  def self.lint_color_message(issue_count)
    color = issue_count == 0 ? '23D96C' : 'e05d44'
    message = issue_count == 0 ? 'clean' : "#{issue_count} issues"
    [color, message]
  end

  def self.cukes_color_message(passed, total)
    color = (passed == total && total > 0) ? '23D96C' : 'e05d44'
    ["#{passed}/#{total}", color]
  end
end

Badges.run
