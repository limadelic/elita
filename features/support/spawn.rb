module Spawn
  def realm
    @scratch || "apps/elita/agents/elita"
  end

  def gate
    @scratch ? File.join(@scratch, 'bin', 'el') : "../../../../apps/el/el"
  end

  def spawn(args)
    (
      "cd #{realm} && " +
      "TAPE=#{tape} " +
      "LIVE=#{live} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{gate} " +
      "#{args}"
    ).strip
  end

  def command(args)
    (
      "cd #{realm} && " +
      "TAPE=#{tape} " +
      "LIVE=#{live} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{gate} " +
      "#{args}"
    ).strip
  end

  def launch(cmd, prompt, puppet_name = nil)
    config = env(puppet_name)
    @reader, @writer, @pid = PTY.spawn(config, "/bin/sh", "-c", cmd)
    watch(@pid)
    @mutex = nil
    wait(prompt)
  end

  def env(puppet_name)
    config = base
    config["PATH"] = spine
    puppet(config, puppet_name)
    prime(config)
    claude(config)
    config
  end

  def puppet(config, name)
    return unless name

    config["PUPPET_NAME"] = name
    config["EL_FROM"] = name
  end

  def claude(config)
    return unless @scratch

    stub = File.join(@scratch, 'bin', 'claude')
    config["CLAUDE"] = stub if File.exist?(stub)
  end

  def prime(config)
    return unless ENV["EL_SYSTEM_PROMPT"]

    config["EL_SYSTEM_PROMPT"] = ENV["EL_SYSTEM_PROMPT"]
  end

  def base
    {
      "TAPE" => tape,
      "LIVE" => live,
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test",
      "ELITA_RUN" => flux
    }
  end

  def tape
    ENV["TAPE"] || "replay"
  end

  def live
    ENV["LIVE"] || ""
  end

  def flux
    ENV["ELITA_RUN"] || ""
  end

  def spine
    [(@scratch ? "#{@scratch}/bin" : nil), ENV["PATH"]].compact.join(":")
  end

  def run(cmd)
    output = ""
    reader, writer, pid = mint(cmd)
    watch(pid)
    extract(reader, Time.now + 30, output)
    kill(writer, pid)
    output
  end

  def mint(cmd)
    cmd_env = cmd.include?("@") ? cloak(cmd) : cmd
    PTY.spawn("/bin/sh", "-c", cmd_env)
  end

  def cloak(cmd)
    unique_id = "ask_#{Time.now.to_i}#{rand(1000)}"
    "ELITA_RUN=#{unique_id} #{cmd}"
  end

  def kill(writer, pid)
    snuff(pid)
    seal(writer)
  end

  def snuff(pid)
    Process.wait(pid) if pid
  end

  def seal(writer)
    return unless open?(writer)

    writer.close
  end

  def open?(writer)
    writer && !writer.closed?
  end

  def reset(args)
    @transcript = ""
    @transcript_stripped = ""
    @screen = Screen.new
    cmd = spawn(args)
    prompt = query(args)
    puppet_name = tag(args)
    launch(cmd, prompt, puppet_name)
  end

  def query(args)
    return "claude" if args.include?("claude")

    unfold(args)
  end

  def unfold(args)
    words = args.split
    return "el" if words.empty?

    dub(words)
  end

  def tag(args)
    words = args.split
    return "el" if words.empty?

    dub(words)
  end

  def dub(words)
    as_index = words.index("as")
    as_index ? words[as_index + 1] : words.first
  end

  def brand(value)
    value.force_encoding("UTF-8") rescue value.to_s
  end

  def strip(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(
      /\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, ""
    )
  end
end
