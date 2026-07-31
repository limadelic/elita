#!/usr/bin/env ruby

require_relative 'index'

module Report
  def self.run
    prefix = ENV.fetch('PREFIX', '')
    Index.generate(prefix)
  end
end

Report.run
