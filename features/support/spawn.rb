module Spawn
  def spawn(args)
    escript_path = "../../../../apps/el/el"
    (
      "cd apps/elita/agents/elita && " +
      "TAPE=#{ENV['TAPE'] || 'replay'} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{escript_path} " +
      "#{args}"
    ).strip
  end

  def command(args)
    tape = ENV["TAPE"] || "replay"
    escript_path = "../../../../apps/el/el"
    (
      "cd apps/elita/agents/elita && " +
      "TAPE=#{tape} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{escript_path} " +
      "#{args}"
    ).strip
  end

  def launch(cmd, prompt)
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test"
    }
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
    cmd = spawn(args)
    prompt = args.split.first || "el"
    launch(cmd, prompt)
  end

  def encode(value)
    value.force_encoding("UTF-8") rescue value.to_s
  end

  def strip(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9;]*m/, "")
  end
end
