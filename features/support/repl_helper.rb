module ReplHelper
  def cassette_dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    ensure_cassette
    @transcript = ""
    @transcript_stripped = ""
    env = build_env
    cmd = spawn_cmd(args)
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait_for_prompt(args.split.first || "el")
  end

  def one_shot(args)
    ensure_cassette
    tape = ENV["TAPE"] || "replay"
    cmd = "cd apps/elita/agents/elita && TAPE=#{tape} CASSETTE=#{@cassette} CASSETTE_DIR=#{cassette_dir} MIX_ENV=test ../../../../apps/el/el #{args}"
    output = ""
    timeout = Time.now + 30

    begin
      reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
      while Time.now < timeout
        ready = IO.select([reader], nil, nil, 0.1)
        if ready
          chunk = reader.readpartial(4096)
          output << chunk
        end
      end
    rescue EOFError
    ensure
      Process.wait(pid) if pid
      writer.close if writer && !writer.closed?
    end

    output
  end

  def send(input, prompt)
    raise "PTY not initialized" unless @writer
    @writer.write("#{input}\n")
    @writer.flush
    wait_for_prompt(prompt)
  end

  def transcript
    @transcript_stripped || ""
  end

  def drain_pty
    return unless @reader

    begin
      while true
        ready = IO.select([@reader], nil, nil, 0.1)
        if ready
          chunk = @reader.readpartial(4096)
          chunk = safe_encode(chunk)
          @transcript << chunk if @transcript
          stripped_chunk = safe_encode(strip_ansi(chunk))
          @transcript_stripped << stripped_chunk if @transcript_stripped
        else
          break
        end
      end
    rescue EOFError
    end
  end

  private

  def ensure_cassette
    @cassette ||= "greet"
  end

  def build_env
    {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => cassette_dir,
      "CLOCK" => @clock,
      "MIX_ENV" => "test"
    }
  end

  def safe_encode(text)
    text.force_encoding("UTF-8") rescue text.to_s
  end

  def spawn_cmd(args)
    env = build_env
    vars = env.map { |k, v| "#{k}=#{v}" }.join(" ")
    "cd apps/elita/agents/elita && #{vars} ../../../../apps/el/el #{args}".strip
  end

  def strip_ansi(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9;]*m/, "")
  end

  def wait_for_prompt(prompt_word)
    output = ""
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    timeout = Time.now + duration
    pattern = "#{prompt_word}>"

    begin
      while Time.now < timeout
        ready = IO.select([@reader], nil, nil, 0.1)
        if ready
          chunk = @reader.readpartial(4096)
          chunk = safe_encode(chunk)
          output << chunk
          @transcript << chunk if @transcript
          stripped_chunk = safe_encode(strip_ansi(chunk))
          @transcript_stripped << stripped_chunk if @transcript_stripped
          return output if output.include?(pattern)
        end
      end
    rescue EOFError
    end

    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

World(ReplHelper)
