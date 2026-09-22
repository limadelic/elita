#!/usr/bin/env ruby

require 'json'

module Cover
  def self.run(prefix)
    percent = coverage_percent
    return if percent.nil?

    color, message = color_message(percent)
    write_json(prefix, color, message)
  end

  def self.coverage_percent
    pct = ENV['COVERAGE_PERCENT']
    return nil unless present?(pct)

    pct.to_f
  end

  def self.present?(value)
    !value.nil? && !value.empty?
  end

  def self.write_json(prefix, color, message)
    json = JSON.generate(Badges.badge('cover', message, color))
    File.write("site/#{prefix}/cover.json", json)
  end

  def self.color_message(percent)
    [color_for_percent(percent), "#{format('%.1f', percent)}%"]
  end

  def self.color_for_percent(percent)
    [[80.0, '23D96C'], [50.0, 'dfb317'], [0.0, 'e05d44']].find { |threshold, _| percent >= threshold }[1]
  end
end
