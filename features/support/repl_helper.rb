module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    @cassette = @cassette || "greet"
    reset(args)
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run(cmd)
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
    append(chunk, strip(chunk))
  end

  def append(chunk, stripped)
    chunk = encode(chunk)
    @transcript << chunk if @transcript
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  private

  def absorb(pty)
    output = ""
    safe { read(pty, output) }
    output
  end

  def safe
    yield
  rescue EOFError
  end

  def read(pty, output)
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
    timeout = deadline
    attempt(output, pattern, timeout) || timeout_error(pattern, output)
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

  def run(cmd)
    output = ""
    reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
    extract(reader, Time.now + 30, output)
    kill(writer, pid)
    output
  end

  def extract(reader, timeout, output)
    safe { await(reader, timeout, output) }
  end

  def await(reader, timeout, output)
    while Time.now < timeout
      ready = IO.select([reader], nil, nil, 0.1)
      output << reader.readpartial(4096) if ready
    end
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

  def deadline
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    Time.now + duration
  end

  def attempt(output, pattern, timeout)
    begin
      poll(output, pattern, timeout)
    rescue EOFError
    end
  end

  def poll(output, pattern, timeout)
    while Time.now < timeout
      next if (chunk = fetch(@reader)).empty?

      log(chunk, output)
      return output if output.include?(pattern)
    end
  end

  def log(chunk, output)
    output << chunk
    @transcript << chunk if @transcript
    stripped = strip(chunk)
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  def timeout_error(pattern, output)
    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

require_relative "search"
require_relative "assert"

World(ReplHelper, Search, Assert)
