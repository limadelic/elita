require 'timeout'

Around do |scenario, block|
  timeout_secs = ENV["TAPE"] == "rec" ? 300 : 40
  Timeout.timeout(timeout_secs) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s"
end

Before do |scenario|
  @cassette = scenario.tags.map(&:name).grep(/^@(\w+)$/) { $1 }.last || "greet"
  initialize_scenario_cursor
end

After do
  if @pid
    begin
      Process.kill("TERM", @pid)
      Process.wait(@pid, Process::WNOHANG)
    rescue Errno::ESRCH
    end
  end
  @writer.close if @writer && !@writer.closed?
end
