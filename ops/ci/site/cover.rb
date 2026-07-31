#!/usr/bin/env ruby

require 'fileutils'

module Cover
  def self.run
    fail('coverage artifact missing') unless File.directory?('/tmp/cover-art')

    copy
    validate
  end

  def self.copy
    transfer
    tidy
  end

  def self.transfer
    success = system("cp -r /tmp/cover-art/* site/")
    fail('coverage copy failed') unless success
  end

  def self.tidy
    FileUtils.mv('/tmp/cover-art', '/tmp/cover-art-done') rescue nil
  end

  def self.validate
    fail('coverage artifact corrupted or incomplete') unless published?
  end

  def self.published?
    File.exist?('site/cover.json') || File.directory?('site/cover')
  end

  def self.fail(msg)
    puts msg
    exit 1
  end
end

Cover.run if __FILE__ == $PROGRAM_NAME
