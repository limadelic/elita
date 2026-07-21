module Feed
  def drain
    return unless @reader
    return if @mutex

    chunk = absorb(@reader)
    append(chunk, strip(chunk))
  end

  def drain_thread_loop(reader, transcript, transcript_stripped, screen, mutex)
    loop do
      ready = IO.select([reader], nil, nil, 0.05)
      next unless ready

      chunk = reader.readpartial(4096)
      drain_encode_and_store(chunk, transcript, transcript_stripped, screen, mutex)
    end
  rescue StandardError
  end

  def drain_encode_and_store(chunk, transcript, transcript_stripped, screen, mutex)
    encoded = chunk.chars.map(&:ord).pack("C*").force_encoding("UTF-8").scrub("")
    stripped = strip_ansi(encoded)
    store_encoded(transcript, transcript_stripped, screen, mutex, encoded, stripped)
  end

  def strip_ansi(encoded)
    pattern = /\e\[[0-9]*[GfH]|\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/
    encoded.scrub("").gsub(pattern, "")
  rescue
    ""
  end

  def store_encoded(transcript, transcript_stripped, screen, mutex, encoded, stripped)
    mutex.synchronize do
      transcript&.<< encoded
      screen&.feed(encoded)
      transcript_stripped&.<< stripped
    end
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
end
