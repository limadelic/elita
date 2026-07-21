module Daemon
  def setup_daemon
    ENV["ELITA_RUN"] = "cukes"
    check_and_start_daemon
  end

  def check_and_start_daemon
    node_name = "elita-cukes"
    daemon_exists?(node_name) && stop_daemon && sleep(0.5)
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
    home = ENV["HOME"]
    "ELITA_RUN=cukes TAPE=#{tape} CASSETTE_DIR=#{cassette_dir} " \
    "HOME=#{home} MIX_ENV=test #{el_path} daemon >>#{@daemon_log} 2>&1 &"
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
end
