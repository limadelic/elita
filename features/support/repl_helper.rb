module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    @cassette = @cassette || "greet"
    @sessions ||= {}
    reset(args)
    store_session(args)
  end

  def store_session(args)
    name = session_name(args)
    prompt = session_name(args)
    mutex = Mutex.new
    drain_thread = start_background_drain(@reader, @transcript, @transcript_stripped, mutex)
    @sessions[name] = {
      reader: @reader,
      writer: @writer,
      pid: @pid,
      screen: @screen,
      transcript: @transcript,
      transcript_stripped: @transcript_stripped,
      prompt: prompt,
      mutex: mutex,
      drain_thread: drain_thread,
      buffer_pos: 0
    }
    @current = name
  end

  def start_background_drain(reader, transcript, transcript_stripped, mutex)
    return nil unless reader
    Thread.new do
      begin
        loop do
          ready = IO.select([reader], nil, nil, 0.05)
          next unless ready
          chunk = reader.readpartial(4096)
          encoded = (chunk.force_encoding("UTF-8") rescue chunk.to_s)
          stripped = (encoded.scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "") rescue "")
          mutex.synchronize do
            transcript << encoded if transcript
            transcript_stripped << stripped if transcript_stripped
          end
        end
      rescue EOFError
      rescue => _
      end
    end
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run(cmd)
  end

  def send(input, prompt)
    @sessions ||= {}
    if @sessions.key?(prompt)
      activate(prompt)
    end
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
    if input == "/exit"
      raise "Session still alive" unless closed?
    else
      actual_prompt = @sessions[prompt]&.dig(:prompt) || prompt
      wait(actual_prompt)
    end
  end

  def activate(name)
    session = @sessions[name]
    return unless session
    @reader = session[:reader]
    @writer = session[:writer]
    @pid = session[:pid]
    @screen = session[:screen]
    @transcript = session[:transcript]
    @transcript_stripped = session[:transcript_stripped]
    @mutex = session[:mutex]
    @buffer_pos = session[:buffer_pos]
    @drain_thread = session[:drain_thread]
  end

  def transcript
    @transcript_stripped || ""
  end

  def drain
    return unless @reader
    return if @mutex

    chunk = absorb(@reader)
    append(chunk, strip(chunk))
  end

  def append(chunk, stripped)
    chunk = encode(chunk)
    if @mutex
      @mutex.synchronize do
        @transcript << chunk if @transcript
        stripped = encode(stripped)
        @transcript_stripped << stripped if @transcript_stripped
      end
    else
      @transcript << chunk if @transcript
      stripped = encode(stripped)
      @transcript_stripped << stripped if @transcript_stripped
    end
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

    if @drain_thread
      !@drain_thread.alive?
    else
      ready = IO.select([@reader], nil, nil, 0.1)
      return false unless ready

      @reader.readpartial(1)
      false
    end
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
    pattern = prompt_word == "claude" ? "▐▛███▜▌" : "#{prompt_word}>"
    timeout = deadline
    attempt(output, pattern, timeout) || timeout_error(pattern, output)
  end

  def deadline
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    Time.now + duration
  end

  def timeout_error(pattern, output)
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

require_relative "spawn"
require_relative "drain"
require_relative "search"
require_relative "assert"

World(ReplHelper, Spawn, Drain, Search, Assert)
