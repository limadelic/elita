require 'timeout'
require 'fileutils'
require 'webrick'
require 'json'

module Hooks
end

BeforeAll do
  root = File.expand_path("../../..", __FILE__)
  el_dir = File.join(root, "apps/el")
  system("cd #{el_dir} && mix escript.build") || raise("Failed to build el escript")
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
  @cassette = tape_tag ? tape_tag.sub("@tape:", "") : File.basename(scenario.location.file, ".feature")
  @tape_on_miss = scenario.tags.map(&:name).find { |t| t.start_with?("@tape_on_miss:") }
  @tape_on_miss = @tape_on_miss ? @tape_on_miss.sub("@tape_on_miss:", "") : nil
  init
  start_stub_server if @tape_on_miss == "live"
end

Before('@malko') do
  @scratch = Dir.mktmpdir
  write_stub_claude
end

After do |scenario|
  ensure_stub_server_stopped
  reap_puppet_processes
end

After('@malko') do
  FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
end

def reap_puppet_processes
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

    kill_orphaned_scripts
  end
  @reader.close if @reader && !@reader.closed?
  @writer.close if @writer && !@writer.closed?
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

def start_stub_server
  @stub_port = 19999
  @stub_server = WEBrick::HTTPServer.new(
    Port: @stub_port,
    AccessLog: [],
    Logger: WEBrick::Log.new("/dev/null")
  )

  @stub_server.mount_proc("/v1/messages") do |req, res|
    if req.request_method == "POST"
      res["Content-Type"] = "application/json"
      res.body = JSON.generate({
        content: [{ type: "text", text: "response from stubbed server" }]
      })
    end
  end

  @stub_thread = Thread.new { @stub_server.start }
  sleep 0.1
  ENV["ANTHROPIC_BASE_URL"] = "http://localhost:#{@stub_port}"
end

def ensure_stub_server_stopped
  if @stub_server
    @stub_server.shutdown
    @stub_thread&.join(1) if @stub_thread
    ENV.delete("ANTHROPIC_BASE_URL")
  end
rescue => e
  # Ignore errors during shutdown
end
