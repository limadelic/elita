#!/usr/bin/env ruby

require 'json'
require 'open3'
require 'uri'

branch = ENV['HEAD_REF'] || ENV['BRANCH']
prefix = branch == 'main' ? '' : "#{branch}/"
pages_url = "https://limadelic.github.io/elita"

credo_json_url = "#{pages_url}/#{prefix}lint.json"
credo_json_encoded = URI.encode_www_form_component(credo_json_url)
credo_report_url = "#{pages_url}/#{prefix}credo.html"
credo_badge = "[![credo](https://img.shields.io/endpoint?url=#{credo_json_encoded})](#{credo_report_url})"

cukes_json_url = "#{pages_url}/#{prefix}cukes.json"
cukes_json_encoded = URI.encode_www_form_component(cukes_json_url)
cukes_report_url = "#{pages_url}/#{prefix}cukes.html"
cukes_badge = "[![cukes](https://img.shields.io/endpoint?url=#{cukes_json_encoded})](#{cukes_report_url})"

badge_content = "#{credo_badge} #{cukes_badge}"

cmd = "gh pr view #{ENV['PR_NUMBER']} --json body -q .body"
body, _status = Open3.capture2(cmd)
body = body.strip

marker_start = '<!-- cukes-badge-start -->'
marker_end = '<!-- cukes-badge-end -->'

if body.include?(marker_start) && body.include?(marker_end)
  regex = /#{Regexp.escape(marker_start)}.*?#{Regexp.escape(marker_end)}/m
  replacement = "#{marker_start}\n#{badge_content}\n#{marker_end}"
  body.gsub!(regex, replacement)
else
  body = "#{marker_start}\n#{badge_content}\n#{marker_end}\n\n#{body}"
end

File.write('/tmp/pr_body.txt', body)
system("gh pr edit #{ENV['PR_NUMBER']} --body-file /tmp/pr_body.txt")
