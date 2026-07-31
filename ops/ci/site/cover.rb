#!/usr/bin/env ruby

require 'fileutils'

module Cover
  def self.run
    return unless File.directory?('/tmp/cover-art')

    copy
    validate
  end

  def self.copy
    run_copy_command
    cleanup_source
  end

  def self.run_copy_command
    success = system("cp -r /tmp/cover-art/* site/")
    exit_fail('coverage copy failed') unless success
  end

  def self.cleanup_source
    FileUtils.mv('/tmp/cover-art', '/tmp/cover-art-done') rescue nil
  end

  def self.validate
    exit_fail('coverage artifact corrupted or incomplete') unless published?
  end

  def self.published?
    File.exist?('site/cover.json') || File.directory?('site/cover')
  end

  def self.exit_fail(msg)
    puts msg
    exit 1
  end
end

Cover.run if __FILE__ == $PROGRAM_NAME
