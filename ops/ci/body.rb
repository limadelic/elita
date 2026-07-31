#!/usr/bin/env ruby

require_relative 'badge'

module Body
  def self.run
    content = File.read('/tmp/body.md')
    content = strip_badge_block(content)
    content = strip_bare_shields(content)
    content = normalize_trailing(content)
    content = Badge.append(content)
    File.write('/tmp/body.md', content)
  end

  def self.strip_badge_block(content)
    content.gsub(/<!-- badges-start -->.*?<!-- badges-end -->\n/m, '')
  end

  def self.strip_bare_shields(content)
    content.gsub(/.*img\.shields\.io.*limadelic.*elita.*\n/, '')
  end

  def self.normalize_trailing(content)
    stripped = content.sub(/\n+\z/, '')
    stripped.empty? ? '' : stripped + "\n"
  end
end

Body.run
