module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    @cassette = @cassette || "greet"
    reset_state(args)
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run_one(cmd)
  end

  def send(input, prompt)
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
    wait(prompt)
  end

  def transcript
    @transcript_stripped || ""
  end

  def drain
    return unless @reader

    chunk = absorb(@reader)
    record_transcript(chunk, strip(chunk))
  end

  def record_transcript(chunk, stripped)
    chunk = encode(chunk)
    @transcript << chunk if @transcript
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  private

  def absorb(pty)
    output = ""
    absorb_loop(pty, output)
    output
  end

  def absorb_loop(pty, output)
    absorb_safe { read_loop(pty, output) }
  end

  def absorb_safe
    yield
  rescue EOFError
  end

  def read_loop(pty, output)
    loop do
      ready = IO.select([pty], nil, nil, 0.1)
      break unless ready

      output << pty.readpartial(4096)
    end
  end

  def fetch(pty)
    ready = IO.select([pty], nil, nil, 0.1)
    return "" unless ready

    encode(pty.readpartial(4096))
  rescue EOFError
    ""
  end

  def encode(value)
    value.force_encoding("UTF-8") rescue value.to_s
  end

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

  def strip(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9;]*m/, "")
  end

  def wait(prompt_word)
    output = ""
    pattern = "#{prompt_word}>"
    timeout = calc_timeout
    wait_loop(output, pattern, timeout) || fail_wait(pattern, output)
  end

  def start_pty(cmd, prompt)
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test"
    }
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait(prompt)
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

  def run_one(cmd)
    output = ""
    reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
    drain_output(reader, Time.now + 30, output)
    cleanup_pty(writer, pid)
    output
  end

  def drain_output(reader, timeout, output)
    drain_safe { read_until(reader, timeout, output) }
  end

  def drain_safe
    yield
  rescue EOFError
  end

  def read_until(reader, timeout, output)
    while Time.now < timeout
      ready = IO.select([reader], nil, nil, 0.1)
      output << reader.readpartial(4096) if ready
    end
  end

  def cleanup_pty(writer, pid)
    Process.wait(pid) if pid
    writer.close if writer && !writer.closed?
  end

  def reset_state(args)
    @transcript = ""
    @transcript_stripped = ""
    cmd = spawn(args)
    prompt = args.split.first || "el"
    start_pty(cmd, prompt)
  end

  def calc_timeout
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    Time.now + duration
  end

  def wait_loop(output, pattern, timeout)
    begin
      loop_until_match(output, pattern, timeout)
    rescue EOFError
    end
  end

  def loop_until_match(output, pattern, timeout)
    while Time.now < timeout
      next if (chunk = fetch(@reader)).empty?

      record_chunk(chunk, output)
      return output if output.include?(pattern)
    end
  end

  def record_chunk(chunk, output)
    output << chunk
    @transcript << chunk if @transcript
    stripped = strip(chunk)
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  def fail_wait(pattern, output)
    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end
