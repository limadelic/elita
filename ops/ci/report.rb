#!/usr/bin/env ruby

require 'json'
require 'fileutils'

module Report
  def self.run
    prefix = compute_prefix
    FileUtils.mkdir_p("site/#{prefix}")
    html = build_html
    File.write("site/#{prefix}/report.html", html)
    write_summary if summary_ready?
  end

  def self.compute_prefix
    branch = ENV['BRANCH']&.sub(%r{/merge$}, '')
    return '' if branch == 'main' || branch == 'test'

    repo = ENV['GITHUB_REPOSITORY']
    cmd = %Q{gh api repos/#{repo}/pulls -q '.[] | select(.head.ref=="#{branch}") | .number' | head -1}
    pr_num = `#{cmd}`.strip
    return "#{pr_num}/" unless pr_num.empty?

    "#{branch}/"
  end

  def self.build_html
    html = header
    html << credo_section
    html << cucumber_section
    html << footer
    html
  end

  def self.header
    <<~HTML
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
        </style>
      </head>
      <body>
    HTML
  end

  def self.credo_section
    issues = load_credo_issues
    return clean_message if issues.empty?

    issue_table(issues)
  end

  def self.load_credo_issues
    return [] unless File.exist?('/tmp/credo.json')

    credo = JSON.parse(File.read('/tmp/credo.json'))
    credo['issues'] || []
  end

  def self.clean_message
    "<h1>credo</h1>\n<div class=\"clean\">✓ 0 issues — clean</div>\n"
  end

  def self.issue_table(issues)
    html = "<h1>credo — #{issues.length} issues</h1>\n"
    html << "<table>\n<thead>\n"
    html << "<tr><th>File</th><th>Line</th><th>Check</th><th>Message</th></tr>\n"
    html << "</thead>\n<tbody>\n"
    issues.each { |issue| html << issue_row(issue) }
    html << "</tbody>\n</table>\n"
    html
  end

  def self.issue_row(issue)
    file = issue['filename'] || ''
    line = issue['line_no'] || ''
    check = issue['check'] || ''
    message = escape_html(issue['message'] || '')
    "<tr><td>#{file}</td><td>#{line}</td><td>#{check}</td><td>#{message}</td></tr>\n"
  end

  def self.escape_html(text)
    text.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;')
  end

  def self.cucumber_section
    html = "<h2>Cucumber</h2>\n"
    return html unless File.exist?('reports/cucumber.html')

    content = File.read('reports/cucumber.html')
    match = content.match(/<body[^>]*>(.*)<\/body>/m)
    html << match[1].strip if match
    html
  end

  def self.footer
    "</body>\n</html>"
  end

  def self.summary_ready?
    File.exist?('reports/cucumber.json') && ENV['GITHUB_STEP_SUMMARY']
  end

  def self.write_summary
    data = JSON.parse(File.read('reports/cucumber.json'))
    scenarios = data.flat_map { |f| f['elements'] || [] }
    passed = scenarios.count { |sc| scenario_passed?(sc) }
    total = scenarios.length
    summary = summary_header(passed, total)
    data.each { |feature| summary << feature_line(feature) }
    File.write(ENV['GITHUB_STEP_SUMMARY'], summary)
  end

  def self.summary_header(passed, total)
    "## Cucumber Tests\n\n✅ **#{passed}/#{total}** scenarios passed\n\n"
  end

  def self.feature_line(feature)
    name = File.basename(feature['uri'])
    scenarios = feature['elements'] || []
    passed = scenarios.count { |sc| scenario_passed?(sc) }
    "- #{name}: #{passed}/#{scenarios.length}\n"
  end

  def self.scenario_passed?(scenario)
    (scenario['steps'] || []).all? { |s| s.dig('result', 'status') == 'passed' }
  end
end

Report.run
