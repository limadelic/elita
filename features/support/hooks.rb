require 'timeout'

Around do |scenario, block|
  Timeout.timeout(timeout) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after #{timeout}s"
end

Before do |scenario|
  @cassette = cassette(scenario) || File.basename(scenario.location.file, ".feature")
  @clock = clock(scenario)
  reset
end

After do
  kill_process if @pid
  @reader&.close unless @reader&.closed?
  @writer&.close unless @writer&.closed?
end

private

def timeout
  return 300 if ENV["TAPE"] == "rec"
  return 600 if ENV["TAPE"].nil? && ENV["COVER"] == "1"
  70
end

def cassette(scenario)
  tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }
  return tag.sub("@tape:", "") if tag

  test_case = scenario.instance_variable_get(:@test_case)
  return ENV['CASSETTE'] unless test_case&.respond_to?(:rows)

  rows = test_case.rows
  return ENV['CASSETTE'] unless rows&.any?
  return ENV['CASSETTE'] unless rows.first&.respond_to?(:to_h)

  rows.first.to_h&.dig('cassette') || ENV['CASSETTE']
end

def clock(scenario)
  test_case = scenario.instance_variable_get(:@test_case)
  return ENV['CLOCK'] unless test_case&.respond_to?(:rows)

  rows = test_case.rows
  return ENV['CLOCK'] unless rows&.any?
  return ENV['CLOCK'] unless rows.first&.respond_to?(:to_h)

  rows.first.to_h&.dig('clock') || ENV['CLOCK']
end

def kill_process
  Process.kill("TERM", @pid)
  Process.wait(@pid, Process::WNOHANG)
rescue Errno::ESRCH
end
