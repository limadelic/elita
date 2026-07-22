#!/usr/bin/env ruby

require 'json'
require 'fileutils'

module Badges
  def self.run
    pref = prefix
    FileUtils.mkdir_p("site/#{pref}")
    quality(pref)
    cukes(pref)
  end

  def self.prefix
    branch = trim
    return '' if main?(branch)

    tag(branch)
  end

  def self.tag(branch)
    pr = number(branch)
    pr.empty? ? "#{branch}/" : "#{pr}/"
  end

  def self.trim
    ENV['BRANCH'].sub(%r{/merge$}, '')
  end

  def self.main?(branch)
    branch == 'main' || branch == 'test'
  end

  def self.number(branch)
    repo = ENV['GITHUB_REPOSITORY']
    cmd = %Q{gh api repos/#{repo}/pulls -q '.[] | select(.head.ref=="#{branch}") | .number' | head -1}
    `#{cmd}`.strip
  end

  def self.quality(pref)
    return unless File.exist?('/tmp/credo.json')

    credo = JSON.parse(File.read('/tmp/credo.json'))
    color, message = lint(credo['issues'].length)
    json = JSON.generate(badge('credo', message, color))
    File.write("site/#{pref}/lint.json", json)
  end

  def self.cukes(pref)
    scen = scenarios
    report(pref, scen) if scen
  end

  def self.scenarios
    return nil unless File.exist?('reports/cucumber.json')

    data = JSON.parse(File.read('reports/cucumber.json'))
    elements(data)
  end

  def self.elements(data)
    data.flat_map { |f| rows(f) }
  end

  def self.rows(file)
    file['elements'] || []
  end

  def self.report(pref, scenarios)
    n = passed(scenarios)
    msg, color = outcome(n, scenarios.length)
    File.write("site/#{pref}/cukes.json", JSON.generate(badge('cukes', msg, color, 'cucumber')))
    File.write("site/#{pref}/cukes_badge.txt", "cukes: #{msg}")
  end

  def self.passed(scenarios)
    scenarios.count { |sc| ok?(sc) }
  end

  def self.ok?(scenario)
    stepped?(scenario['steps'] || [])
  end

  def self.stepped?(steps)
    steps.all? { |s| s.dig('result', 'status') == 'passed' }
  end

  def self.badge(label, message, color, logo = nil)
    b = core(label, message, color)
    brand(b, logo) if logo
    b.compact!
    b
  end

  def self.core(label, message, color)
    {
      schemaVersion: 1,
      label: label,
      message: message,
      color: color,
      labelColor: '173647'
    }
  end

  def self.brand(b, logo)
    b[:namedLogo] = logo
    b[:logoColor] = 'white'
  end

  def self.lint(count)
    return ['23D96C', 'clean'] if count == 0

    ['e05d44', "#{count} issues"]
  end

  def self.outcome(n, total)
    color = pass?(n, total) ? '23D96C' : 'e05d44'
    ["#{n}/#{total}", color]
  end

  def self.pass?(n, total)
    n == total && total > 0
  end
end

Badges.run
