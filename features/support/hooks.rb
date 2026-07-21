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
  setup_scratch_home
  setup_daemon
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
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s"
end

Before do |scenario|
  tape_tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }
  @cassette = tape_tag ? tape_tag.sub("@tape:", "") : File.basename(scenario.location.file, ".feature")
  push_cassette_to_daemon
  @tracked_pids = []
  init
end

Before('@malko') do
  setup_malko_scratch
  guard_live_claude
end

After do |_scenario|
  reset_daemon_agents
  reap_without_orphans
end

AfterAll do
  stop_daemon
  kill_orphaned_scripts_gracefully
end

After('@malko') do
  clean_malko_scratch
end
