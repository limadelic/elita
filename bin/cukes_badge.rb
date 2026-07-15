#!/usr/bin/env ruby

require 'json'
require 'fileutils'

branch = ENV['BRANCH'].sub(%r{/merge$}, '')
FileUtils.mkdir_p("site/#{branch}")

if File.exist?('reports/cucumber.json')
  data = JSON.parse(File.read('reports/cucumber.json'))
  scenarios = data.flat_map { |f| f['elements'] || [] }
  passed = scenarios.count { |sc| (sc['steps'] || []).all? { |s| s.dig('result', 'status') == 'passed' } }
  total = scenarios.length
  message = "#{passed}/#{total}"
else
  passed = 0
  total = 0
  message = '0/0'
end

color = (passed == total && total > 0) ? '23D96C' : 'e05d44'

badge = {
  schemaVersion: 1,
  label: 'cukes',
  message: message,
  color: color,
  namedLogo: 'cucumber',
  logoColor: 'white',
  labelColor: '173647'
}

File.write("site/#{branch}/cukes.json", JSON.generate(badge))
File.write("site/#{branch}/cukes_badge.txt", "cukes: #{message}")
