#!/usr/bin/env ruby

require 'json'
require 'fileutils'

module Badges
  def self.run
    branch = ENV['BRANCH'].sub(%r{/merge$}, '')
    FileUtils.mkdir_p("site/#{branch}")
    lint_badges(branch)
    cukes_badges(branch)
  end

  def self.lint_badges(branch)
    return unless File.exist?('/tmp/credo.json')

    credo = JSON.parse(File.read('/tmp/credo.json'))
    issue_count = credo['issues'].length
    color, message = lint_color_message(issue_count)
    json = JSON.generate(badge('credo', message, color))
    File.write("site/#{branch}/lint.json", json)
  end

  def self.cukes_badges(branch)
    return unless File.exist?('reports/cucumber.json')

    data = JSON.parse(File.read('reports/cucumber.json'))
    scenarios = data.flat_map { |f| f['elements'] || [] }
    write_cukes_files(branch, scenarios)
  end

  def self.write_cukes_files(branch, scenarios)
    passed = count_passed(scenarios)
    message, color = cukes_color_message(passed, scenarios.length)
    File.write("site/#{branch}/cukes.json", JSON.generate(badge('cukes', message, color, 'cucumber')))
    File.write("site/#{branch}/cukes_badge.txt", "cukes: #{message}")
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
