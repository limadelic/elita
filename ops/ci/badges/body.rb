#!/usr/bin/env ruby

require_relative 'badge'

module Body
  def self.run
    content = File.read('/tmp/body.md')
    content = strip_badge_block(content)
    content = Badge.append(content)
    File.write('/tmp/body.md', content)
  end

  def self.strip_badge_block(content)
    content.gsub(/<!-- badges-start -->.*?<!-- badges-end -->\n/m, '')
  end
end

Body.run
