require 'timeout'

Around do |scenario, block|
  Timeout.timeout(40) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after 40s"
end

Before do |scenario|
  @cassette = scenario.tags.map(&:name).grep(/^@(\w+)$/) { $1 }.first || "greet"
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
