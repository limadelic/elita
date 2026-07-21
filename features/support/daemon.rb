module Daemon
  def summon
    ENV["ELITA_RUN"] = "cukes"
    bootstrap
  end

  def bootstrap
    node_name = "elita-cukes"
    retire(node_name)
    ignite
    readied
  end

  def retire(node_name)
    return unless active?(node_name)

    halt
    sleep(0.5)
  end

  def halt
    stopd_script = File.expand_path("../stopd.exs", __FILE__)
    system("elixir #{stopd_script} >/dev/null 2>&1")
  end

  def active?(node_name)
    `epmd -names 2>/dev/null`.include?(node_name)
  end

  def ignite
    @daemon_log = logfile
    FileUtils.mkdir_p(File.dirname(@daemon_log))
    system("cd apps/elita/agents/elita && #{invoke}")
  end

  def logfile
    tmp = Dir.tmpdir
    scratchpad = File.join(tmp, "elita_dude_#{Process.uid}")
    FileUtils.mkdir_p(scratchpad)
    File.join(scratchpad, "daemon_cukes.log")
  end

  def invoke
    tape = ENV["TAPE"] || "replay"
    cassette_dir = File.expand_path("../cassettes", __dir__)
    el_path = "../../../../apps/el/el"
    home = ENV["HOME"]
    "ELITA_RUN=cukes TAPE=#{tape} CASSETTE_DIR=#{cassette_dir} " \
    "HOME=#{home} MIX_ENV=test #{el_path} daemon >>#{@daemon_log} 2>&1 &"
  end

  def readied
    deadline = Time.now + 5.0
    loop do
      return if active?("elita-cukes")

      late?(deadline)
      sleep 0.1
    end
  end

  def late?(deadline)
    raise fault if Time.now > deadline
  end

  def fault
    log_tail = File.exist?(@daemon_log) ? File.readlines(@daemon_log).last(20).join : "no log"
    "Daemon elita-cukes@127.0.0.1 failed to start:\n#{log_tail}"
  end
end
