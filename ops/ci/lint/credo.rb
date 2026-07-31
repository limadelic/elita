#!/usr/bin/env ruby

require 'json'

module Credo
  def self.run
    system('mix credo list --format json > /tmp/credo.json')
    return unless File.exist?('/tmp/credo.json')

    report
  end

  def self.report
    data = JSON.parse(File.read('/tmp/credo.json'))
    add_header
    add_summary(data)
    report_issues(data['issues'])
  end

  def self.add_header
    system('echo "## Lint Violations" >> $GITHUB_STEP_SUMMARY')
  end

  def self.add_summary(data)
    count = data['issues'].length
    system("echo \"Found #{count} issues\" >> $GITHUB_STEP_SUMMARY")
    system('echo "" >> $GITHUB_STEP_SUMMARY')
  end

  def self.report_issues(issues)
    return if issues.empty?

    output_issues(issues)
  end

  def self.output_issues(issues)
    add_table_header
    issues.each { |issue| add_row(issue) }
  end

  def self.add_table_header
    system('echo "| File | Line | Check | Message |" >> $GITHUB_STEP_SUMMARY')
    system('echo "|------|------|-------|---------|" >> $GITHUB_STEP_SUMMARY')
  end

  def self.add_row(issue)
    file = issue['filename']
    line = issue['line_no']
    check = issue['check']
    message = issue['message']
    system("echo \"::error file=#{file},line=#{line},title=#{check}::#{message}\"")
    short = File.basename(file)
    system("echo \"| #{short} | #{line} | #{check} | #{message} |\" >> $GITHUB_STEP_SUMMARY")
  end
end

Credo.run if __FILE__ == $PROGRAM_NAME
