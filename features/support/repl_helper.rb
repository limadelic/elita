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
    wait(prompt) unless input == "/exit"
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

  def closed?
    timeout = Time.now + 2
    loop do
      break if reader_eof?
      break if process_exited?
      return false if Time.now > timeout

      sleep 0.05
    end
    true
  end

  private

  def reader_eof?
    return false unless @reader

    ready = IO.select([@reader], nil, nil, 0.1)
    return false unless ready

    @reader.readpartial(1)
    false
  rescue EOFError
    true
  end

  def process_exited?
    return false unless @pid

    Process.wait(@pid, Process::WNOHANG)
    true
  rescue Errno::ECHILD
    true
  end

  def wait(prompt_word)
    output = ""
    pattern = "#{prompt_word}>"
    timeout = deadline
    attempt(output, pattern, timeout) || timeout_error(pattern, output)
  end

  def deadline
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    Time.now + duration
  end

  def timeout_error(pattern, output)
    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

require_relative "spawn"
require_relative "drain"
require_relative "search"
require_relative "assert"

World(ReplHelper, Spawn, Drain, Search, Assert)
