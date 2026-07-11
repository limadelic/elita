module Drain
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
    if @mutex
      return ""
    end
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
    stripped = ""
    if @mutex
      last_pos_full = @transcript ? @transcript.length : 0
      last_pos_stripped = @transcript_stripped ? @transcript_stripped.length : 0
      while Time.now < timeout
        @mutex.synchronize do
          if @transcript && @transcript.length > last_pos_full
            chunk = @transcript[last_pos_full...@transcript.length]
            output << chunk
            last_pos_full = @transcript.length
          end
          if @transcript_stripped && @transcript_stripped.length > last_pos_stripped
            chunk = @transcript_stripped[last_pos_stripped...@transcript_stripped.length]
            stripped << chunk
            last_pos_stripped = @transcript_stripped.length
          end
        end
        return output if stripped.include?(pattern)
        sleep 0.01
      end
    else
      while Time.now < timeout
        next if (chunk = fetch(@reader)).empty?

        log(chunk, output)
        stripped << strip(chunk)
        return output if stripped.include?(pattern)
      end
    end
  end

  def log(chunk, output)
    output << chunk
    if @mutex
      @mutex.synchronize do
        @transcript << chunk if @transcript
        @screen.feed(chunk) if @screen
        stripped = strip(chunk)
        stripped = encode(stripped)
        @transcript_stripped << stripped if @transcript_stripped
      end
    else
      @transcript << chunk if @transcript
      @screen.feed(chunk) if @screen
      stripped = strip(chunk)
      stripped = encode(stripped)
      @transcript_stripped << stripped if @transcript_stripped
    end
  end
end
