module ReplHelper
  def cassettes
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    default
    @transcript = ""
    @transcript_stripped = ""
    merged = env
    merged = ::ENV.to_h.merge(merged)
    cmd = spawn_cmd(args)
    @reader, @writer, @pid = PTY.spawn(merged, "/bin/sh", "-c", cmd)
    wait_for_prompt(args.split.first || "el")
  end

  def one_shot(args)
    default
    tape = ::ENV["TAPE"] || "replay"
    clock_part = @clock ? "CLOCK=#{@clock} " : ""
    cmd = "cd apps/elita/agents/elita && TAPE=#{tape} CASSETTE=#{@cassette} CASSETTE_DIR=#{cassettes} MIX_ENV=test #{clock_part}../../../../apps/el/el #{args}"
    output = ""
    timeout = Time.now + 30
    env_hash = { "TAPE" => tape, "CASSETTE" => @cassette, "CASSETTE_DIR" => cassettes, "MIX_ENV" => "test" }
    env_hash["CLOCK"] = @clock if @clock
    env = ::ENV.to_h.merge(env_hash)

    begin
      reader, writer, pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
      while Time.now < timeout
        ready = IO.select([reader], nil, nil, 0.1)
        next unless ready
        chunk = reader.readpartial(4096)
        output << chunk
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
      loop do
        ready = IO.select([@reader], nil, nil, 0.1)
        break unless ready
        chunk = @reader.readpartial(4096)
        chunk = encode(chunk)
        @transcript << chunk if @transcript
        stripped_chunk = encode(strip_ansi(chunk))
        @transcript_stripped << stripped_chunk if @transcript_stripped
      end
    rescue EOFError
    end
  end

  private

  def default
    @cassette ||= "greet"
  end

  def env
    hash = {
      "TAPE" => ::ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => cassettes,
      "MIX_ENV" => "test"
    }
    hash["CLOCK"] = @clock if @clock
    hash
  end

  def encode(text)
    text.force_encoding("UTF-8") rescue text.to_s
  end

  def spawn_cmd(args)
    hash = env
    vars = hash.map { |k, v| "#{k}=#{v}" }.join(" ")
    "cd apps/elita/agents/elita && #{vars} ../../../../apps/el/el #{args}".strip
  end

  def strip_ansi(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9;]*m/, "")
  end

  def wait_for_prompt(prompt_word)
    output = ""
    duration = ::ENV["TAPE"] == "rec" ? 300 : 30
    timeout = Time.now + duration
    pattern = "#{prompt_word}>"

    begin
      while Time.now < timeout
        ready = IO.select([@reader], nil, nil, 0.1)
        next unless ready
        chunk = @reader.readpartial(4096)
        chunk = encode(chunk)
        output << chunk
        @transcript << chunk if @transcript
        stripped_chunk = encode(strip_ansi(chunk))
        @transcript_stripped << stripped_chunk if @transcript_stripped
        return output if output.include?(pattern)
      end
    rescue EOFError
    end

    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

World(ReplHelper)
