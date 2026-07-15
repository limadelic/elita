#!/usr/bin/env ruby

require 'json'

def passed?(scenario)
  (scenario['steps'] || []).all? { |s| s.dig('result', 'status') == 'passed' }
end

if File.exist?('reports/cucumber.json')
  data = JSON.parse(File.read('reports/cucumber.json'))
  scenarios = data.flat_map { |f| f['elements'] || [] }
  passed = scenarios.count { |sc| passed?(sc) }
  total = scenarios.length
  summary = "## Cucumber Tests\n\n✅ **#{passed}/#{total}** scenarios passed\n\n"
  data.each do |feature|
    feature_name = File.basename(feature['uri'])
    feature_scenarios = feature['elements'] || []
    feature_passed = feature_scenarios.count { |sc| passed?(sc) }
    summary << "- #{feature_name}: #{feature_passed}/#{feature_scenarios.length}\n"
  end
  File.write(ENV['GITHUB_STEP_SUMMARY'], summary)
end
