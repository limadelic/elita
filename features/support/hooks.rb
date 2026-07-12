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
  @scratch = Dir.mktmpdir('scratch', File.expand_path('../../tmp', __dir__))
  bin_dir = File.join(@scratch, 'bin')
  Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
  el_escript = File.expand_path('../../apps/el/el', __dir__)
  el_link = File.join(bin_dir, 'el')
  File.symlink(el_escript, el_link) unless File.exist?(el_link)
  guard_live_claude if ENV['TAPE'] == 'rec'
  write_stub_claude unless ENV['TAPE'] == 'rec'
end

Before('@autonomy') do
  prompt = "When you receive a message that begins with from someone, reply by typing: tell SENDER your answer"
  ENV['EL_SYSTEM_PROMPT'] = prompt
end

After('@autonomy') do
  ENV.delete('EL_SYSTEM_PROMPT')
end

After do |scenario|
  ensure_stub_server_stopped
  reap_all_sessions
end

After('@malko') do
  FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
end

def guard_live_claude
  bin_dir = File.join(@scratch, 'bin')
  stub_path = File.join(bin_dir, 'claude')
  raise "TAPE=rec but stub exists at #{stub_path}" if File.exist?(stub_path)

  expected = '/opt/homebrew/bin/claude'
  actual = `which claude 2>/dev/null`.strip
  raise "TAPE=rec requires claude at #{expected}, found: #{actual}" unless actual == expected
end

def reap_all_sessions
  @sessions ||= {}
  killed_any = false

  @sessions.each do |name, session|
    next unless session && session[:pid]
    kill_process(session[:pid])
    killed_any = true
    session[:reader]&.close
    session[:writer]&.close
  end

  if killed_any
    kill_orphaned_scripts
  elsif @pid
    kill_process(@pid)
    kill_orphaned_scripts
  end

  @reader&.close if @reader && !@reader.closed?
  @writer&.close if @writer && !@writer.closed?
  @sessions.clear
end

def kill_process(pid)
  return unless pid
  begin
    pgid = Process.getpgid(pid)
    Process.kill("TERM", -pgid)
    sleep 0.1
    Process.kill("KILL", -pgid)
  rescue Errno::ESRCH
  rescue Errno::EPERM
  end

  begin
    Process.wait(pid, Process::WNOHANG)
  rescue Errno::ESRCH
  end
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
