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
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{el_path} " +
      "#{args}"
    ).strip
  end

  def launch(cmd, prompt, puppet_name = nil)
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test"
    }
    env["PATH"] = [(@scratch ? "#{@scratch}/bin" : nil), ENV["PATH"]].compact.join(":")
    env["PUPPET_NAME"] = puppet_name if puppet_name
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait(prompt)
  end

  def run(cmd)
    output = ""
    reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
    extract(reader, Time.now + 30, output)
    kill(writer, pid)
    output
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
    words.empty? ? "el" : words.last
  end

  def session_name(args)
    words = args.split
    words.empty? ? "el" : words.last
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
