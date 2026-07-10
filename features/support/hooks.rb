require 'timeout'
require 'fileutils'

module Hooks
end

Around do |scenario, block|
  timeout_secs = if ENV["TAPE"] == "rec"
                   300
                 else
                   70
                 end
  Timeout.timeout(timeout_secs) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s"
end

Before do |scenario|
  tape_tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }
  @cassette = tape_tag ? tape_tag.sub(
    "@tape:",
    ""
  ) : File.basename(scenario.location.file, ".feature")
  @scratch = Dir.mktmpdir
  write_stub_claude
  init
end

After do
  if @pid
    begin
      Process.kill("TERM", @pid)
      Process.wait(@pid, Process::WNOHANG)
    rescue Errno::ESRCH
    end
  end
  @reader.close if @reader && !@reader.closed?
  @writer.close if @writer && !@writer.closed?
  FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
end
