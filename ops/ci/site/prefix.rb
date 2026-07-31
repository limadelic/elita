#!/usr/bin/env ruby

module Prefix
  def self.run
    branch = ENV['BRANCH']
    return if branch.nil?

    puts compute(branch)
  end

  def self.compute(branch)
    return '' if main_or_test?(branch)

    "#{pr_or_branch(branch)}/"
  end

  def self.pr_or_branch(branch)
    fetch_pr(branch) || branch
  end

  def self.main_or_test?(branch)
    branch == 'main' || branch == 'test'
  end

  def self.fetch_pr(branch)
    cmd = "gh api repos/#{ENV['GITHUB_REPOSITORY']}/pulls -q " \
          "\".[] | select(.head.ref==\\\"#{branch}\\\") | .number\" | head -1"
    result = `#{cmd} 2>/dev/null`.chomp
    result.empty? ? nil : result
  end
end

Prefix.run if __FILE__ == $PROGRAM_NAME
