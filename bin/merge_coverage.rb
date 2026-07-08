#!/usr/bin/env ruby

require 'fileutils'

# Find all coverage files
files = Dir.glob('/Users/mike/dev/self/elita-qa/coverdata.*.ets')

if files.empty?
  puts "No coverage files found"
  exit 1
end

puts "Found #{files.length} coverage files"

# Use Erlang's cover to merge them
require 'open3'

# Start erl and load all the coverage files
erl_code = files.map { |f| ":cover.import('#{f}')." }.join("\n")
erl_code += "\n:cover.export('/Users/mike/dev/self/elita-qa/coverdata.ets')."
erl_code += "\nhalt."

cmd = "erl -noshell -eval \"#{erl_code}\""

stdout, stderr, status = Open3.capture3(cmd)
puts stdout
puts stderr if stderr && !stderr.empty?

if File.exist?('/Users/mike/dev/self/elita-qa/coverdata.ets')
  puts "Coverage merged successfully"
  puts `ls -lh /Users/mike/dev/self/elita-qa/coverdata.ets`
else
  puts "Failed to merge coverage"
  exit 1
end
