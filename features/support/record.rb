module Record
  def transcript
    @transcript_stripped || ""
  end

  def drain
    return unless @reader

    guard
  end

  def guard
    return if @mutex

    pull
  end

  def pull
    chunk = absorb(@reader)
    append(chunk, strip(chunk))
  end

  def append(chunk, stripped)
    chunk = encode(chunk)
    @mutex ? locked(chunk, stripped) : raw(chunk, stripped)
  end

  def locked(chunk, stripped)
    @mutex.synchronize do
      log(chunk)
      record(stripped)
    end
  end

  def log(chunk)
    @transcript << chunk if @transcript
  end

  def record(stripped)
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end

  def raw(chunk, stripped)
    log(chunk)
    record(stripped)
  end

  def encode(chunk)
    chunk.force_encoding("UTF-8")
  rescue
    chunk.to_s
  end

  def scrub(encoded)
    encoded.scrub("").gsub(/\e\[[0-9]*[GfH]/, " ").gsub(/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")
  rescue
    ""
  end

  def sync(encoded, stripped, transcript, transcript_stripped, mutex)
    mutex.synchronize { save(encoded, stripped, transcript, transcript_stripped) }
  end

  def save(encoded, stripped, transcript, transcript_stripped)
    push(transcript, encoded)
    push(transcript_stripped, stripped)
  end

  def push(buffer, data)
    buffer << data if buffer
  end
end
