#!/usr/bin/env ruby

module Comment
  def self.run
    pr_num = fetch_pr
    return unless pr_num

    update_or_create(pr_num)
  end

  def self.fetch_pr
    head = ENV['GITHUB_REF_NAME']
    cmd = "gh pr list --head #{head} --json number --jq '.[] | .number' 2>/dev/null"
    exec_gh(cmd)
  end

  def self.exec_gh(cmd)
    `#{cmd}`.chomp rescue nil
  end

  def self.update_or_create(pr_num)
    marker = '<!-- elita-coverage-report -->'
    body = coverage_body(marker)
    repo = ENV['GITHUB_REPOSITORY']

    comment_id = find_comment(repo, pr_num, marker)
    update_pr_comment(repo, pr_num, comment_id, body)
  end

  def self.coverage_body(marker)
    coverage = ENV['COVERAGE_PERCENT']
    "#{marker}\n\n## Coverage: #{coverage}%"
  end

  def self.find_comment(repo, pr_num, marker)
    cmd = find_comment_cmd(repo, pr_num, marker)
    exec_gh(cmd)
  end

  def self.find_comment_cmd(repo, pr_num, marker)
    "gh api repos/#{repo}/issues/#{pr_num}/comments --jq " \
    "\".[] | select(.body | contains(\\\"#{marker}\\\")) | .id\" " \
    "2>/dev/null | head -1"
  end

  def self.update_pr_comment(repo, pr_num, comment_id, body)
    comment_id ? patch_comment(repo, pr_num, comment_id, body) : create_comment(pr_num, body)
  end

  def self.patch_comment(repo, pr_num, comment_id, body)
    system(
      "gh api repos/#{repo}/issues/#{pr_num}/comments/#{comment_id} " \
                 "-X PATCH -f body='#{body}'"
    )
  end

  def self.create_comment(pr_num, body)
    system("gh pr comment #{pr_num} --body '#{body}'")
  end
end

Comment.run if __FILE__ == $PROGRAM_NAME
