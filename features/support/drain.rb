module Drain
  def fix_encoding(chunk)
    chunk.chars.map(&:ord).pack("C*").force_encoding("UTF-8").scrub("")
  rescue
    chunk.to_s
  end

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
    return "" if @mutex

    ready = IO.select([pty], nil, nil, 0.1)
    return "" unless ready

    encode(pty.readpartial(4096))
  rescue EOFError
    ""
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

  def attempt(output, pattern, timeout)
    begin
      poll(output, pattern, timeout)
    rescue EOFError
    end
  end

  def poll(output, pattern, timeout)
    @mutex ? poll_with_mutex(output, pattern, timeout) : poll_without_mutex(output, pattern, timeout)
  end

  def poll_with_mutex(output, pattern, timeout)
    stripped = ""
    last_pos_full = @transcript ? @transcript.length : 0
    last_pos_stripped = @transcript_stripped ? @transcript_stripped.length : 0
    poll_loop_with_mutex(output, pattern, timeout, stripped, last_pos_full, last_pos_stripped)
  end

  def poll_loop_with_mutex(output, pattern, timeout, stripped, last_pos_full, last_pos_stripped)
    while Time.now < timeout
      last_pos_full = sync_full(output, last_pos_full)
      last_pos_stripped = sync_stripped(stripped, last_pos_stripped)
      return output if stripped.include?(pattern)

      sleep 0.01
    end
  end

  def sync_full(output, last_pos)
    @mutex.synchronize do
      return last_pos unless @transcript && @transcript.length > last_pos

      chunk = @transcript[last_pos...@transcript.length]
      output << chunk
      @transcript.length
    end
  end

  def sync_stripped(stripped, last_pos)
    @mutex.synchronize do
      return last_pos unless @transcript_stripped && @transcript_stripped.length > last_pos

      chunk = @transcript_stripped[last_pos...@transcript_stripped.length]
      stripped << chunk
      @transcript_stripped.length
    end
  end

  def poll_without_mutex(output, pattern, timeout)
    stripped = ""
    while Time.now < timeout
      next if (chunk = fetch(@reader)).empty?

      log(chunk, output)
      stripped << strip(chunk)
      return output if stripped.include?(pattern)
    end
  end

  def log(chunk, output)
    output << chunk
    @mutex ? log_with_mutex(chunk) : log_without_mutex(chunk)
  end

  def log_with_mutex(chunk)
    fixed_chunk = fix_encoding(chunk)
    @mutex.synchronize do
      @transcript << chunk if @transcript
      @screen.feed(fixed_chunk) if @screen
      stripped = encode(strip(chunk))
      @transcript_stripped << stripped if @transcript_stripped
    end
  end

  def log_without_mutex(chunk)
    fixed_chunk = fix_encoding(chunk)
    @transcript << chunk if @transcript
    @screen.feed(fixed_chunk) if @screen
    stripped = encode(strip(chunk))
    @transcript_stripped << stripped if @transcript_stripped
  end
end
