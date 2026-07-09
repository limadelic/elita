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
    chunk = encode(chunk)
    @transcript << chunk if @transcript
    stripped_chunk = strip(chunk)
    stripped_chunk = encode(stripped_chunk)
    @transcript_stripped << stripped_chunk if @transcript_stripped
  end

  private

  def absorb(pty)
    output = ""
    absorb_loop(pty, output)
    output
  end

  def absorb_loop(pty, output)
    begin
      loop do
        ready = IO.select([pty], nil, nil, 0.1)
        break unless ready
        output << pty.readpartial(4096)
      end
    rescue EOFError
    end
  end

  def fetch(pty)
    ready = IO.select([pty], nil, nil, 0.1)
    return "" unless ready

    chunk = pty.readpartial(4096)
    encode(chunk)
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
    timeout = Time.now + 30
    reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
    drain_output(reader, timeout, output)
    cleanup_pty(writer, pid)
    output
  end

  def drain_output(reader, timeout, output)
    begin
      while Time.now < timeout
        ready = IO.select([reader], nil, nil, 0.1)
        output << reader.readpartial(4096) if ready
      end
    rescue EOFError
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
      while Time.now < timeout
        chunk = fetch(@reader)
        next if chunk.empty?
        record_chunk(chunk, output)
        return output if output.include?(pattern)
      end
    rescue EOFError
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

World(ReplHelper)
