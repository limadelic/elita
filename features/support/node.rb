module Node
  def summon
    ENV["ELITA_RUN"] = "cukes"
    bootstrap
  end

  def bootstrap
    node_name = "elita-cukes"
    retire(node_name)
    ignite
    readied
    start_cover
  end

  def retire(node_name)
    return unless active?(node_name)

    halt
    sleep(0.5)
  end

  def halt
    stopd_script = File.expand_path("../stopd.exs", __FILE__)
    result = system("elixir #{stopd_script}")
    raise "Failed to halt node" unless result
  end

  def active?(node_name)
    `epmd -names 2>/dev/null`.include?(node_name)
  end

  def ignite
    @node_log = logfile
    FileUtils.mkdir_p(File.dirname(@node_log))
    pid = spawn_node
    Process.detach(pid)
    watch(pid)
  end

  def logfile
    tmp = Dir.tmpdir
    scratchpad = File.join(tmp, "elita_dude_#{Process.uid}")
    FileUtils.mkdir_p(scratchpad)
    File.join(scratchpad, "node_cukes.log")
  end

  def spawn_node
    env = node_env
    el_path = "../../../../apps/el/el"
    Process.spawn(
      env,
      "#{el_path} node",
      chdir: "apps/elita/agents/elita",
      [:out, :err] => [@node_log, "a"]
    )
  end

  def node_env
    base_env.tap do |env|
      clock = node_clock
      env["CLOCK"] = clock if clock
    end
  end

  def base_env
    {
      "ELITA_RUN" => "cukes",
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE_DIR" => File.expand_path("../cassettes", __dir__),
      "HOME" => ENV["HOME"],
      "MIX_ENV" => "test"
    }
  end

  def node_clock
    unfrozen? ? nil : frozen_clock
  end

  def unfrozen?
    ENV["TAPE"] == "rec" || ENV["LIVE"] == "1"
  end

  def frozen_clock
    @clock || ENV.fetch("CLOCK", "2025-07-07 10:00:00")
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
    log_tail = File.exist?(@node_log) ? File.readlines(@node_log).last(20).join : "no log"
    "Node elita-cukes@127.0.0.1 failed to start:\n#{log_tail}"
  end

  def start_cover
    cover_script = File.expand_path("../cover_start.exs", __FILE__)
    result = system("elixir #{cover_script}")
    raise "Failed to start coverage" unless result
  end
end
