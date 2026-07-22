module Feed
  def drain
    return unless ready?

    chunk = absorb(@reader)
    append(chunk, strip(chunk))
  end

  def ready?
    @reader && !@mutex
  end

  def drain_thread_loop(reader, transcript, transcript_stripped, screen, mutex)
    loop do
      process_if_ready(reader, transcript, transcript_stripped, screen, mutex)
    end
  rescue StandardError
  end

  def process_if_ready(reader, transcript, transcript_stripped, screen, mutex)
    ready = IO.select([reader], nil, nil, 0.05)
    return unless ready

    chunk = reader.readpartial(4096)
    feed(chunk, transcript, transcript_stripped, screen, mutex)
  end

  def feed(chunk, transcript, transcript_stripped, screen, mutex)
    encoded = chunk.chars.map(&:ord).pack("C*").force_encoding("UTF-8").scrub("")
    stripped = strip_ansi(encoded)
    store(transcript, transcript_stripped, screen, mutex, encoded, stripped)
  end

  def strip_ansi(encoded)
    pattern = /\e\[[0-9]*[GfH]|\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/
    encoded.scrub("").gsub(pattern, "")
  rescue
    ""
  end

  def store(transcript, transcript_stripped, screen, mutex, encoded, stripped)
    mutex.synchronize do
      add_to_transcript(transcript, encoded)
      add_to_screen(screen, encoded)
      add_to_stripped(transcript_stripped, stripped)
    end
  end

  def add_to_transcript(transcript, encoded)
    transcript&.<< encoded
  end

  def add_to_screen(screen, encoded)
    screen&.feed(encoded)
  end

  def add_to_stripped(transcript_stripped, stripped)
    transcript_stripped&.<< stripped
  end

  def append(chunk, stripped)
    chunk = encode(chunk)
    @mutex ? sync(chunk, stripped) : async(chunk, stripped)
  end

  def sync(chunk, stripped)
    @mutex.synchronize do
      push_chunk(chunk)
      push_stripped(stripped)
    end
  end

  def async(chunk, stripped)
    push_chunk(chunk)
    push_stripped(stripped)
  end

  def push_chunk(chunk)
    @transcript << chunk if @transcript
  end

  def push_stripped(stripped)
    encoded = encode(stripped)
    @transcript_stripped << encoded if @transcript_stripped
  end
end
