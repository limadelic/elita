require 'timeout'
require 'fileutils'
require_relative 'daemon'
require_relative 'home'
require_relative 'cassette'
require_relative 'reap'
require_relative 'kill'
require_relative 'track'
require_relative 'guard'

module Hooks
end

World(Daemon)
World(Home)
World(Cassette)
World(Reap)
World(Kill)
World(Track)
World(Guard)

BeforeAll do
  Timeout.timeout(30) do
    nest
    summon
  end
rescue Timeout::Error
  raise "BeforeAll setup timed out after 30s"
end

Around do |scenario, block|
  timeout_secs = case
                 when ENV["TAPE"] == "rec"
                   300
                 when ENV["LIVE"] == "1"
                   150
                 else
                   70
                 end
  Timeout.timeout(timeout_secs) { block.call }
rescue Timeout::Error
  scram(scenario, timeout_secs)
end

def scram(scenario, timeout_secs)
  glimpse
  slash
  purge
  Cucumber.wants_to_quit = true
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s (hung, killed)"
end

def glimpse
  return unless @transcript

  lines = @transcript.split("\n").last(40)
  STDERR.puts "\n=== Last 40 lines of transcript ===\n#{lines.join("\n")}\n"
end

def slash
  snip if @drain_thread
end

def snip
  @drain_thread.kill rescue nil
end

Before do |scenario|
  tape_tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }
  @cassette = tape_tag ? tape_tag.sub("@tape:", "") : File.basename(scenario.location.file, ".feature")
  @delivered = false
  @tracked_pids = []
  init
end

Before('@malko') do
  burrow
  enforce
end

After do |_scenario|
  Timeout.timeout(30) do
    revoke
    bundle
  end
rescue Timeout::Error
  STDERR.puts "After hook timed out after 30s"
  purge
  slash
end

AfterAll do
  Timeout.timeout(30) do
    halt
    expunge
  end
rescue Timeout::Error
  STDERR.puts "AfterAll cleanup timed out after 30s"
end

After('@malko') do
  scour
end
