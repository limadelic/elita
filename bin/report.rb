#!/usr/bin/env ruby

require 'json'
require 'fileutils'

branch = ENV['BRANCH'].sub(%r{/merge$}, '')
FileUtils.mkdir_p("site/#{branch}")

html = <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Test Report</title>
    <style>
      body { background: #1a1a1a; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; }
      h1 { color: #fff; margin: 0 0 20px 0; }
      h2 { color: #fff; margin: 30px 0 15px 0; border-top: 1px solid #444; padding-top: 20px; }
      .clean { color: #23D96C; font-size: 1.1em; margin: 20px 0; }
      table { width: 100%; border-collapse: collapse; margin: 20px 0; }
      th { background: #173647; color: #fff; padding: 12px; text-align: left; border-bottom: 1px solid #444; font-weight: 600; }
      td { padding: 12px; border-bottom: 1px solid #333; }
      tr:hover { background: #2a2a2a; }
      .cukes-section { margin-top: 30px; }
    </style>
  </head>
  <body>
HTML

if File.exist?('/tmp/credo.json')
  credo = JSON.parse(File.read('/tmp/credo.json'))
  issues = credo['issues'] || []
else
  issues = []
end

if issues.empty?
  html << "<h1>credo</h1>\n<div class=\"clean\">✓ 0 issues — clean</div>\n"
else
  html << "<h1>credo — #{issues.length} issues</h1>\n"
  html << "<table>\n<thead>\n<tr><th>File</th><th>Line</th><th>Check</th><th>Message</th></tr>\n</thead>\n<tbody>\n"
  issues.each do |issue|
    file = issue['filename'] || ''
    line = issue['line_no'] || ''
    check = issue['check'] || ''
    message = (issue['message'] || '').gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;')
    html << "<tr><td>#{file}</td><td>#{line}</td><td>#{check}</td><td>#{message}</td></tr>\n"
  end
  html << "</tbody>\n</table>\n"
end

html << "<h2>Cucumber</h2>\n"
if File.exist?('reports/cucumber.html')
  cukes_content = File.read('reports/cucumber.html')
  match = cukes_content.match(/<body[^>]*>(.*)<\/body>/m)
  html << match[1].strip if match
end

html << "</body>\n</html>"
File.write("site/#{branch}/report.html", html)
