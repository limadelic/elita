module Badge
  def self.append(content)
    content = content.dup
    badges.each do |name|
      content = append_if_missing(content, name)
    end
    content
  end

  def self.badges
    %w[lint cukes cover greet]
  end

  def self.append_if_missing(content, badge_name)
    link = send(badge_name)
    return content if content.include?(link)

    append_link(content, link)
  end

  def self.append_link(content, link)
    normalized = content.sub(/\n+\z/, '')
    padding = normalized.empty? ? '' : "\n"
    normalized + padding + link + "\n"
  end

  def self.lint
    url = ENV.fetch('LINT_URL')
    "[![lint](https://img.shields.io/endpoint?url=#{url})](https://github.com/limadelic/elita/actions/workflows/lint.yml)"
  end

  def self.cukes
    pr = ENV.fetch('PR_NUMBER')
    url = ENV.fetch('CUKES_URL')
    "[![cukes](https://img.shields.io/endpoint?url=#{url})](https://limadelic.github.io/elita/#{pr}/report.html)"
  end

  def self.cover
    pr = ENV.fetch('PR_NUMBER')
    url = ENV.fetch('COVER_URL')
    "[![cover](https://img.shields.io/endpoint?url=#{url})](https://limadelic.github.io/elita/#{pr}/cover/index.html)"
  end

  def self.greet
    pr = ENV.fetch('PR_NUMBER')
    "[![greet](https://img.shields.io/badge/greet-video-blue)](https://limadelic.github.io/elita/#{pr}/greet.mp4)"
  end
end
