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
    while Time.now < timeout
      next if (chunk = fetch(@reader)).empty?

      log(chunk, output)
      return output if output.include?(pattern)
    end
  end

  def log(chunk, output)
    output << chunk
    @transcript << chunk if @transcript
    stripped = strip(chunk)
    stripped = encode(stripped)
    @transcript_stripped << stripped if @transcript_stripped
  end
end
