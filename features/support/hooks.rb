require 'timeout'
require 'fileutils'

module Hooks
end

BeforeAll do
  root = File.expand_path("../../..", __FILE__)
  el_dir = File.join(root, "apps/el")
  system("cd #{el_dir} && mix escript.build") || raise("Failed to build el escript")
  setup_daemon
end

Around do |scenario, block|
  timeout_secs = if ENV["TAPE"] == "rec"
                   300
                 elsif ENV["LIVE"] == "1"
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
  tmp_dir = File.expand_path('../../tmp', __dir__)
  FileUtils.mkdir_p(tmp_dir)
  @scratch = Dir.mktmpdir('scratch', tmp_dir)
  bin_dir = File.join(@scratch, 'bin')
  Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
  el_escript = File.expand_path('../../apps/el/el', __dir__)
  el_link = File.join(bin_dir, 'el')
  return if File.exist?(el_link)

  raise "el escript not found at #{el_escript}" unless File.exist?(el_escript)

  FileUtils.cp(el_escript, el_link)
  File.chmod(0755, el_link)
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
  FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
end

def reap_without_orphans
  @sessions ||= {}
  reap_sessions
  close_main_pty
  @sessions.clear
end

def guard_live_claude
  bin_dir = File.join(@scratch, 'bin')
  stub_path = File.join(bin_dir, 'claude')
  raise "Fake claude stub detected at #{stub_path}" if File.exist?(stub_path)

  expected = '/opt/homebrew/bin/claude'
  actual = `which claude 2>/dev/null`.strip
  raise "Claude not found at #{expected}, found: #{actual}" unless actual == expected
end

def reap_all_sessions
  @sessions ||= {}
  killed_any = reap_sessions
  kill_after_reap(killed_any)
  close_main_pty
  @sessions.clear
end

def reap_sessions
  killed = false
  @sessions.each do |_name, session|
    killed = true if close_session(session)
  end
  killed
end

def close_session(session)
  return false unless session&.[](:pid)

  kill_process(session[:pid])
  session[:reader]&.close
  session[:writer]&.close
  true
end

def kill_after_reap(killed_any)
  return kill_orphaned_scripts if killed_any
  return unless @pid

  kill_process(@pid)
  kill_orphaned_scripts
end

def close_main_pty
  safe_close(@reader)
  safe_close(@writer)
end

def safe_close(io)
  return unless io
  return if io.closed?

  io.close
end

def kill_process(pid)
  return unless pid

  kill_process_graceful(pid)
end

def kill_process_graceful(pid)
  begin
    pgid = Process.getpgid(pid)
    Process.kill("TERM", -pgid)
    wait_for_graceful_exit(pgid)
    Process.kill("KILL", -pgid) if still_alive?(pgid)
  rescue Errno::ESRCH, Errno::EPERM
  end
end

def wait_for_graceful_exit(pgid)
  10.times do
    return true unless still_alive?(pgid)

    sleep 0.2
  end
  false
end

def still_alive?(pgid)
  Process.kill(0, -pgid)
  true
rescue Errno::ESRCH, Errno::EPERM
  false
end

def wait_process_end(pid)
  begin
    Process.wait(pid, Process::WNOHANG)
  rescue Errno::ESRCH
  end
end

def kill_orphaned_scripts_gracefully
  orphans = find_script_orphans
  terminate_gracefully(orphans, 2)
end

def kill_orphaned_scripts
  orphans = find_script_orphans
  terminate_pids(orphans, "TERM")
  sleep 0.1
  terminate_pids(orphans, "KILL")
end

def terminate_gracefully(pids, timeout_secs)
  pids.each { |p| Process.kill("TERM", p.to_i) rescue Errno::ESRCH }
  timeout_secs.times do
    remaining = find_script_orphans
    return if remaining.empty?

    sleep 1
  end
  terminate_pids(pids, "KILL")
end

def find_script_orphans
  run_id = ENV["ELITA_RUN"]
  return [] unless run_id

  cmd = "ps eww | grep 'script -q /dev/null' | grep ELITA_RUN=#{run_id} | awk '{print $1}'"
  `#{cmd}`.strip.split("\n").compact
end

def terminate_pids(pids, signal)
  pids.each do |pid_str|
    pid = pid_str.to_i
    next if pid.zero?

    Process.kill(signal, pid) rescue Errno::ESRCH
  end
end

def track_pid(pid)
  @tracked_pids ||= []
  @tracked_pids << pid if pid && pid > 0
end

def kill_tracked_pids
  return if @tracked_pids.nil? || @tracked_pids.empty?

  send_term_signals
  wait_graceful
  send_kill_signals
  @tracked_pids.clear
end

def send_term_signals
  @tracked_pids.each do |pid|
    signal_pid(pid, "TERM")
  end
end

def signal_pid(pid, sig)
  return unless pid_alive?(pid)

  Process.kill(sig, pid)
rescue Errno::ESRCH, Errno::EPERM
  nil
end

def living_pids
  @tracked_pids.select { |pid| pid_alive?(pid) }
end

def wait_graceful
  deadline = Time.now + 2.0
  loop do
    remaining = living_pids
    break if remaining.empty? || Time.now > deadline

    sleep 0.05
  end
end

def send_kill_signals
  @tracked_pids.each do |pid|
    signal_pid(pid, "KILL")
  end
end

def pid_alive?(pid)
  Process.kill(0, pid)
  true
rescue Errno::ESRCH
  false
rescue Errno::EPERM
  true
end

def setup_daemon
  ENV["ELITA_RUN"] = "cukes"
  check_and_start_daemon
end

def check_and_start_daemon
  node_name = "elita-cukes"
  if daemon_exists?(node_name)
    stop_daemon
    sleep 0.5
  end
  launch_daemon_detached
  wait_daemon_ready
end

def stop_daemon
  stopd_script = File.expand_path("../stopd.exs", __FILE__)
  system("elixir #{stopd_script} >/dev/null 2>&1")
end

def daemon_exists?(node_name)
  `epmd -names 2>/dev/null`.include?(node_name)
end

def launch_daemon_detached
  @daemon_log = daemon_log_path
  FileUtils.mkdir_p(File.dirname(@daemon_log))
  system("cd apps/elita/agents/elita && #{daemon_command}")
end

def daemon_log_path
  tmp = Dir.tmpdir
  scratchpad = File.join(tmp, "elita_dude_#{Process.uid}")
  FileUtils.mkdir_p(scratchpad)
  File.join(scratchpad, "daemon_cukes.log")
end

def daemon_command
  tape = ENV["TAPE"] || "replay"
  cassette_dir = File.expand_path("../cassettes", __dir__)
  el_path = "../../../../apps/el/el"
  "ELITA_RUN=cukes TAPE=#{tape} CASSETTE_DIR=#{cassette_dir} " \
  "MIX_ENV=test #{el_path} daemon >>#{@daemon_log} 2>&1 &"
end

def wait_daemon_ready
  deadline = Time.now + 5.0
  loop do
    return if daemon_exists?("elita-cukes")

    raise daemon_startup_error if Time.now > deadline

    sleep 0.1
  end
end

def daemon_startup_error
  log_tail = File.exist?(@daemon_log) ? File.readlines(@daemon_log).last(20).join : "no log"
  "Daemon elita-cukes@127.0.0.1 failed to start:\n#{log_tail}"
end

def push_cassette_to_daemon
  setenv_script = File.expand_path("../setenv.exs", __FILE__)
  cassette_dir = File.expand_path("../cassettes", __dir__)
  system("elixir #{setenv_script} #{@cassette} #{cassette_dir} >/dev/null 2>&1")
rescue StandardError
  # tolerate errors - daemon may not be ready yet
end

def reset_daemon_agents
  reset_script = File.expand_path("../reset.exs", __FILE__)
  system("elixir #{reset_script} >/dev/null 2>&1")
rescue StandardError
  # tolerate errors - daemon may not be running
end
