require 'timeout'

Around do |scenario, block|
  timeout_secs = case ENV["TAPE"]
  when "rec" then 300
  when nil then ENV["COVER"] == "1" ? 600 : 70
  else 70
  end
  Timeout.timeout(timeout_secs) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s"
end

Before do |scenario|
  @cassette = extract_cassette(scenario) || File.basename(scenario.location.file, ".feature")
  initialize_scenario_cursor
end

After do
  kill_process if @pid
  @reader&.close unless @reader&.closed?
  @writer&.close unless @writer&.closed?
end

private

def extract_cassette(scenario)
  tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }
  return tag.sub("@tape:", "") if tag

  test_case = scenario.instance_variable_get(:@test_case)
  return unless test_case&.respond_to?(:rows)

  rows = test_case.rows
  return unless rows&.any?

  row = rows.first.to_h if rows.first.respond_to?(:to_h)
  row&.dig('cassette')
end

def kill_process
  Process.kill("TERM", @pid)
  Process.wait(@pid, Process::WNOHANG)
rescue Errno::ESRCH
end
