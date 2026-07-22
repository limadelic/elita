module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    cassette
    sessions
    reset(args)
    cache(args)
  end

  def cassette
    @cassette ||= "greet"
  end

  def sessions
    @sessions ||= {}
  end

  def cache(args)
    name = tag(args)
    prompt = query(args)
    mutex = Mutex.new
    drain_thread = hatch(@reader, @transcript, @transcript_stripped, mutex)
    @sessions[name] = forge(drain_thread, prompt, mutex)
    @current = name
    @drain_thread = drain_thread
  end

  def forge(drain_thread, prompt, mutex)
    {
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
  end

  def hatch(reader, transcript, transcript_stripped, mutex)
    return nil unless reader

    Thread.new { spin(reader, transcript, transcript_stripped, mutex) }
  end

  def spin(reader, transcript, transcript_stripped, mutex)
    loop { intake(reader, transcript, transcript_stripped, mutex) }
  rescue StandardError
  end

  def intake(reader, transcript, transcript_stripped, mutex)
    ready = IO.select([reader], nil, nil, 0.05)
    return unless ready

    chunk = reader.readpartial(4096)
    flow(chunk, transcript, transcript_stripped, mutex)
  end

  def flow(chunk, transcript, transcript_stripped, mutex)
    encoded = brand(chunk)
    stripped = scrub(encoded)
    sync(encoded, stripped, transcript, transcript_stripped, mutex)
  end

  def brand(chunk)
    chunk.force_encoding("UTF-8")
  rescue StandardError
    chunk.to_s
  end

  def scrub(encoded)
    encoded.scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")
  rescue StandardError
    ""
  end

  def sync(encoded, stripped, transcript, transcript_stripped, mutex)
    mutex.synchronize { ingest(encoded, stripped, transcript, transcript_stripped) }
  end

  def one(args)
    @cassette = @cassette || "greet"
    cmd = command(args)
    run(cmd)
  end

  def post(input, prompt)
    switch(prompt)
    push(input)
    dispatch(input, prompt)
  end

  def switch(prompt)
    activate(prompt) if @sessions.key?(prompt)
  end

  def push(input)
    raise "PTY not initialized" unless @writer

    @writer.write("#{input}\n")
    @writer.flush
  end

  def dispatch(input, prompt)
    input == "/exit" ? assure : pursue(prompt)
  end

  def pursue(prompt)
    actual_prompt = which(prompt)
    wait(actual_prompt)
  end

  def assure
    raise "Session still alive" unless closed?
  end

  def emit(input, prompt)
    sessions
    vet(prompt)
    activate(prompt)
    push(input)
  end

  def vet(prompt)
    raise "Unknown session: #{prompt}" unless @sessions.key?(prompt)
  end

  def collect(prompt, input)
    input == "/exit" ? assure : hold(prompt)
  end

  def hold(prompt)
    actual_prompt = which(prompt)
    wait(actual_prompt) || ""
  end

  def which(prompt)
    return prize(prompt) if @sessions.key?(prompt)

    alt(prompt)
  end

  def prize(prompt)
    @sessions[prompt][:prompt]
  end

  def alt(prompt)
    mine || prompt
  end

  def mine
    @sessions[@current]&.dig(:prompt)
  end

  def activate(name)
    return unless (session = @sessions[name])

    @current = name
    unpack(session)
  end

  def unpack(session)
    %i[reader writer pid screen transcript transcript_stripped mutex buffer_pos drain_thread].each do |key|
      instance_variable_set("@#{key}", session[key])
    end
  end

  private

  def wait(prompt_word)
    pattern = prompt_word == "claude" ? "Claude Code" : "#{prompt_word}>"
    attempt("", pattern, deadline)
  end

  def deadline
    duration = ENV["TAPE"] == "rec" ? 300 : 60
    Time.now + duration
  end
end

require_relative "spawn"
require_relative "drain"
require_relative "search"
require_relative "snap"
require_relative "assert"
require_relative "session_logs"
require_relative "status"
require_relative "record"

World(ReplHelper, Spawn, Drain, Search, Snap, Assert, SessionLogs, Status, Record)
