module Badge
  def self.append(content)
    content + block
  end

  def self.block
    "<!-- badges-start -->\n" \
    "#{lint}\n" \
    "#{cukes}\n" \
    "#{cover}\n" \
    "<!-- badges-end -->\n"
  end

  def self.lint
    pr = ENV.fetch('PR_NUMBER')
    url = ENV.fetch('LINT_URL')
    "[![lint](https://img.shields.io/endpoint?url=#{url})](https://limadelic.github.io/elita/#{pr}/report.html)"
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
end
