#!/usr/bin/env ruby

require 'json'
require 'fileutils'

branch = ENV['BRANCH'].sub(%r{/merge$}, '')
FileUtils.mkdir_p("site/#{branch}")

if File.exist?('/tmp/credo.json')
  credo = JSON.parse(File.read('/tmp/credo.json'))
  issue_count = credo['issues'].length
else
  issue_count = 0
end

color = issue_count == 0 ? '23D96C' : 'e05d44'
message = issue_count == 0 ? 'clean' : "#{issue_count} issues"
badge = {
  schemaVersion: 1,
  label: 'credo',
  message: message,
  color: color,
  labelColor: '173647'
}

File.write("site/#{branch}/lint.json", JSON.generate(badge))
