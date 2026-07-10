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
      pgid = Process.getpgid(@pid)
      Process.kill("TERM", -pgid)
      sleep 0.1
      Process.kill("KILL", -pgid)
    rescue Errno::ESRCH
    rescue Errno::EPERM
    end

    begin
      Process.wait(@pid, Process::WNOHANG)
    rescue Errno::ESRCH
    end

    # Kill any orphaned script processes from this cassette
    kill_orphaned_scripts
  end
  @reader.close if @reader && !@reader.closed?
  @writer.close if @writer && !@writer.closed?
  FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
end

def kill_orphaned_scripts
  orphans = find_script_orphans
  terminate_pids(orphans, "TERM")
  sleep 0.1
  terminate_pids(orphans, "KILL")
end

def find_script_orphans
  cmd = "ps aux | grep 'script -q /dev/null' | grep -v grep | awk '{print $2}'"
  `#{cmd}`.strip.split("\n")
end

def terminate_pids(pids, signal)
  pids.each do |pid_str|
    pid = pid_str.to_i
    next if pid.zero?

    Process.kill(signal, pid) rescue Errno::ESRCH
  end
end
