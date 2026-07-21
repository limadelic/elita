module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    @cassette ||= "greet"
    @sessions ||= {}
    @mutex = Mutex.new
    reset_pty(args)
    setup_drain
    wait_initial_prompt(args)
    store_session(args)
  end

  def setup_drain
    @drain_thread = start_background_drain(@reader, @transcript, @transcript_stripped, @screen, @mutex)
    sleep 0.1
  end

  def reset_pty(args)
    @transcript = ""
    @transcript_stripped = ""
    @screen = Screen.new
    cmd = spawn(args)
    wait_prompt(args)
    puppet_name = session_name(args)
    launch_pty(cmd, puppet_name)
  end

  def launch_pty(cmd, puppet_name = nil)
    env = build_launch_env(puppet_name)
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    track_pid(@pid)
  end

  def wait_initial_prompt(args)
    prompt = wait_prompt(args)
    wait(prompt)
  end

  def store_session(args)
    name = session_name(args)
    @sessions[name] = {
      reader: @reader,
      writer: @writer,
      pid: @pid,
      screen: @screen,
      transcript: @transcript,
      transcript_stripped: @transcript_stripped,
      prompt: name,
      mutex: @mutex,
      drain_thread: @drain_thread,
      buffer_pos: 0
    }
    @current = name
  end

  def start_background_drain(reader, transcript, transcript_stripped, screen, mutex)
    return nil unless reader

    Thread.new { drain_thread_loop(reader, transcript, transcript_stripped, screen, mutex) }
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run(cmd)
  end

  def send(input, prompt)
    send_setup(input, prompt)
    send_handle_result(input, prompt)
  end

  def send_setup(input, prompt)
    @sessions ||= {}
    activate(prompt) if @sessions.key?(prompt)
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
  end

  def send_handle_result(input, prompt)
    if input == "/exit"
      raise "Session still alive" unless closed?

      return
    end
    actual_prompt = @sessions[prompt]&.dig(:prompt) || prompt
    wait(actual_prompt)
  end

  def write_input(input, prompt)
    send_setup(input, prompt)
  end

  def await_result(prompt, input)
    if input == "/exit"
      raise "Session still alive" unless closed?

      return
    end

    maybe_activate(prompt)
    actual_prompt = resolve_prompt(prompt)
    wait(actual_prompt) || ""
  end

  def maybe_activate(prompt)
    activate(prompt) if @sessions.key?(prompt)
  end

  def resolve_prompt(prompt)
    @sessions[prompt]&.dig(:prompt) || prompt
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
    return !@drain_thread.alive? if @drain_thread

    probe_eof
  end

  def probe_eof
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
    duration = ENV["TAPE"] == "rec" ? 300 : 60
    timeout = Time.now + duration
    attempt(output, pattern, timeout) || (raise "Timeout waiting for '#{pattern}' in:\n#{output}")
  end
end

require_relative "spawn"
require_relative "drain"
require_relative "search"
require_relative "assert"
require_relative "session_logs"
require_relative "feed"

World(ReplHelper, Spawn, Drain, Search, Assert, SessionLogs, Feed)
