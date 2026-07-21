module Spawn
  def work_dir
    @scratch || "apps/elita/agents/elita"
  end

  def el_path
    @scratch ? File.join(@scratch, 'bin', 'el') : "../../../../apps/el/el"
  end

  def spawn(args)
    (
      "cd #{work_dir} && " +
      "TAPE=#{ENV['TAPE'] || 'replay'} " +
      "LIVE=#{ENV['LIVE'] || ''} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{el_path} " +
      "#{args}"
    ).strip
  end

  def command(args)
    tape = ENV["TAPE"] || "replay"
    (
      "cd #{work_dir} && " +
      "TAPE=#{tape} " +
      "LIVE=#{ENV['LIVE'] || ''} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{el_path} " +
      "#{args}"
    ).strip
  end

  def launch(cmd, prompt, puppet_name = nil)
    env = build_launch_env(puppet_name)
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    track_pid(@pid)
    @mutex = nil
    wait(prompt)
  end

  def build_launch_env(puppet_name)
    env = base_env
    env["PATH"] = build_path
    env["PUPPET_NAME"] = puppet_name if puppet_name
    env["EL_FROM"] = puppet_name if puppet_name
    env["EL_SYSTEM_PROMPT"] = ENV["EL_SYSTEM_PROMPT"] if ENV["EL_SYSTEM_PROMPT"]
    env
  end

  def base_env
    {
      "TAPE" => ENV["TAPE"] || "replay",
      "LIVE" => ENV["LIVE"] || "",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test",
      "ELITA_RUN" => ENV["ELITA_RUN"] || ""
    }
  end

  def build_path
    [(@scratch ? "#{@scratch}/bin" : nil), ENV["PATH"]].compact.join(":")
  end

  def run(cmd)
    output = ""
    reader, writer, pid = spawn_pty(cmd)
    track_pid(pid)
    extract(reader, Time.now + 30, output)
    kill(writer, pid)
    output
  end

  def spawn_pty(cmd)
    cmd_env = cmd.include?("@") ? env_wrap(cmd) : cmd
    PTY.spawn("/bin/sh", "-c", cmd_env)
  end

  def env_wrap(cmd)
    unique_id = "ask_#{Time.now.to_i}#{rand(1000)}"
    "ELITA_RUN=#{unique_id} #{cmd}"
  end

  def kill(writer, pid)
    Process.wait(pid) if pid
    writer.close if writer && !writer.closed?
  end

  def reset(args)
    @transcript = ""
    @transcript_stripped = ""
    @screen = Screen.new
    cmd = spawn(args)
    prompt = wait_prompt(args)
    puppet_name = session_name(args)
    launch(cmd, prompt, puppet_name)
  end

  def wait_prompt(args)
    return "claude" if args.include?("claude")

    words = args.split
    return "el" if words.empty?

    as_index = words.index("as")
    as_index ? words[as_index + 1] : words.first
  end

  def session_name(args)
    words = args.split
    return "el" if words.empty?

    as_index = words.index("as")
    as_index ? words[as_index + 1] : words.first
  end

  def encode(value)
    value.force_encoding("UTF-8") rescue value.to_s
  end

  def strip(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(
      /\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, ""
    )
  end
end
