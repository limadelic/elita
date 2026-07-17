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

    Thread.new { drain_thread_loop(reader, transcript, transcript_stripped, mutex) }
  end

  def drain_thread_loop(reader, transcript, transcript_stripped, mutex)
    loop { drain_process_chunk(reader, transcript, transcript_stripped, mutex) }
  rescue StandardError
  end

  def drain_process_chunk(reader, transcript, transcript_stripped, mutex)
    ready = IO.select([reader], nil, nil, 0.05)
    return unless ready

    chunk = reader.readpartial(4096)
    drain_encode_and_store(chunk, transcript, transcript_stripped, mutex)
  end

  def drain_encode_and_store(chunk, transcript, transcript_stripped, mutex)
    encoded = (chunk.force_encoding("UTF-8") rescue chunk.to_s)
    stripped = (encoded.scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(
      /\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/,
      ""
    ) rescue "")
    mutex.synchronize do
      transcript << encoded if transcript
      transcript_stripped << stripped if transcript_stripped
    end
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run(cmd)
  end

  def send(input, prompt)
    @sessions ||= {}
    activate(prompt) if @sessions.key?(prompt)
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
    send_handle_result(input, prompt)
  end

  def send_handle_result(input, prompt)
    return verify_closed if input == "/exit"

    actual_prompt = @sessions[prompt]&.dig(:prompt) || prompt
    wait(actual_prompt)
  end

  def verify_closed
    raise "Session still alive" unless closed?
  end

  def write_input(input, prompt)
    @sessions ||= {}
    if @sessions.key?(prompt)
      activate(prompt)
    else
      message = "#{prompt} #{input}"
      @writer.write("#{message}\n")
      @writer.flush
      return
    end
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
  end

  def await_result(prompt, input)
    return verify_closed if input == "/exit"

    actual_prompt = @sessions[prompt]&.dig(:prompt) || prompt
    wait(actual_prompt) || ""
  end

  def activate(name)
    return unless (session = @sessions[name])

    assign_session_attrs(session)
  end

  def assign_session_attrs(session)
    %i[reader writer pid screen transcript transcript_stripped mutex buffer_pos drain_thread].each do |key|
      instance_variable_set("@#{key}", session[key])
    end
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
    @mutex ? append_with_mutex(chunk, stripped) : append_without_mutex(chunk, stripped)
  end

  def append_with_mutex(chunk, stripped)
    @mutex.synchronize do
      @transcript << chunk if @transcript
      stripped = encode(stripped)
      @transcript_stripped << stripped if @transcript_stripped
    end
  end

  def append_without_mutex(chunk, stripped)
    @transcript << chunk if @transcript
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  def closed?
    timeout = Time.now + 2
    close_loop(timeout)
  end

  def close_loop(timeout)
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

    @drain_thread ? drain_thread_eof? : reader_io_eof?
  end

  def drain_thread_eof?
    !@drain_thread.alive?
  end

  def reader_io_eof?
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
    pattern = prompt_word == "claude" ? "Claude Code" : "#{prompt_word}>"
    timeout = deadline
    attempt(output, pattern, timeout) || timeout_error(pattern, output)
  end

  def deadline
    duration = ENV["TAPE"] == "rec" ? 300 : 60
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
require_relative "session_logs"

World(ReplHelper, Spawn, Drain, Search, Assert, SessionLogs)
