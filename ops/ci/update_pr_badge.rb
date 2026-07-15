#!/usr/bin/env ruby

require 'json'
require 'open3'
require 'uri'

module UpdatePrBadge
  MARKER_START = '<!-- cukes-badge-start -->'
  MARKER_END = '<!-- cukes-badge-end -->'

  def self.run
    branch = ENV['HEAD_REF'] || ENV['BRANCH']
    return if branch_health_ok?(branch)

    badge_content = build_badges(branch)
    body = fetch_pr_body
    body = update_pr_body(body, badge_content)
    File.write('/tmp/pr_body.txt', body)
    system("gh pr edit #{ENV['PR_NUMBER']} --body-file /tmp/pr_body.txt")
  end

  def self.branch_health_ok?(branch)
    url = credo_url(branch)
    status = `curl -s -o /dev/null -w "%{http_code}" '#{url}'`
    status.strip != '200'
  end

  def self.credo_url(branch)
    prefix = branch == 'main' ? '' : "#{branch}/"
    "https://limadelic.github.io/elita/#{prefix}lint.json"
  end

  def self.build_badges(branch)
    prefix = branch == 'main' ? '' : "#{branch}/"
    url = "https://limadelic.github.io/elita"
    report = "#{url}/#{prefix}report.html"
    credo_badge = build_badge(url, prefix, 'lint.json', 'credo', report)
    cukes_badge = build_badge(url, prefix, 'cukes.json', 'cukes', report)
    "#{credo_badge} #{cukes_badge}"
  end

  def self.build_badge(url, prefix, json, name, report)
    json_url = "#{url}/#{prefix}#{json}"
    encoded = URI.encode_www_form_component(json_url)
    "[![#{name}](https://img.shields.io/endpoint?url=#{encoded})](#{report})"
  end

  def self.fetch_pr_body
    cmd = "gh pr view #{ENV['PR_NUMBER']} --json body -q .body"
    body, _status = Open3.capture2(cmd)
    body.strip
  end

  def self.update_pr_body(body, badge_content)
    body.include?(MARKER_START) ? replace_badges(body, badge_content) : prepend_badges(body, badge_content)
  end

  def self.replace_badges(body, badge_content)
    regex = /#{Regexp.escape(MARKER_START)}.*?#{Regexp.escape(MARKER_END)}/m
    replacement = "#{MARKER_START}\n#{badge_content}\n#{MARKER_END}"
    body.gsub(regex, replacement)
  end

  def self.prepend_badges(body, badge_content)
    "#{MARKER_START}\n#{badge_content}\n#{MARKER_END}\n\n#{body}"
  end
end

UpdatePrBadge.run
