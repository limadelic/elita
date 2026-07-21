module Record
  def transcript
    @transcript_stripped || ""
  end

  def drain
    return unless usable?

    chunk = absorb(@reader)
    append(chunk, strip(chunk))
  end

  def usable?
    @reader && !@mutex
  end

  def append(chunk, stripped)
    chunk = encode(chunk)
    @mutex ? atom(chunk, stripped) : bare(chunk, stripped)
  end

  def atom(chunk, stripped)
    @mutex.synchronize { ingest(chunk, encode(stripped), @transcript, @transcript_stripped) }
  end

  def bare(chunk, stripped)
    store(chunk, @transcript)
    store(encode(stripped), @transcript_stripped)
  end

  def sync(encoded, stripped, transcript, transcript_stripped, mutex)
    mutex.synchronize { ingest(encoded, stripped, transcript, transcript_stripped) }
  end

  private

  def ingest(encoded, stripped, transcript, transcript_stripped)
    store(encoded, transcript)
    store(stripped, transcript_stripped)
  end

  def store(value, buffer)
    buffer << value if buffer
  end
end
