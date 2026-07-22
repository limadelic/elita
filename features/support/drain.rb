module Drain
  def absorb(pty)
    output = ""
    safe { read(pty, output) }
    output
  end

  def safe
    yield
  rescue EOFError, Errno::EIO
  end

  def read(pty, output)
    loop do
      ready = IO.select([pty], nil, nil, 0.1)
      break unless ready

      output << pty.readpartial(4096)
    end
  end

  def fetch(pty)
    @mutex ? "" : slurp(pty)
  end

  def slurp(pty)
    gulp(pty)
  rescue EOFError
    ""
  end

  def gulp(pty)
    return "" unless ready?(pty)

    encode(pty.readpartial(4096))
  end

  def ready?(pty)
    IO.select([pty], nil, nil, 0.1)
  end

  def extract(reader, timeout, output)
    safe { await(reader, timeout, output) }
  end

  def await(reader, timeout, output)
    while Time.now < timeout
      feed(reader, output)
    end
  end

  def feed(reader, output)
    ready = IO.select([reader], nil, nil, 0.1)
    output << reader.readpartial(4096) if ready
  end

  def attempt(output, pattern, timeout)
    begin
      poll(output, pattern, timeout)
    rescue EOFError
    end
  end

  def poll(output, pattern, timeout)
    @mutex ? lock(output, pattern, timeout) : wild(output, pattern, timeout)
  end

  def lock(output, pattern, timeout)
    stripped = ""
    last_pos_full = full
    last_pos_stripped = span
    cycle(output, pattern, timeout, stripped, last_pos_full, last_pos_stripped)
  end

  def full
    @transcript ? @transcript.length : 0
  end

  def span
    @transcript_stripped ? @transcript_stripped.length : 0
  end

  def cycle(output, pattern, timeout, stripped, last_pos_full, last_pos_stripped)
    loop do
      break if done?(timeout, stripped, pattern)

      hoist(output, last_pos_full)
      glean(stripped, last_pos_stripped)
      sleep 0.01
    end
    output
  end

  def done?(timeout, stripped, pattern)
    Time.now >= timeout || hit?(stripped, pattern)
  end

  def hit?(stripped, pattern)
    stripped.include?(pattern)
  end

  def hoist(output, last_pos)
    @mutex.synchronize do
      return last_pos unless fresh?(last_pos)

      chunk = @transcript[last_pos...@transcript.length]
      output << chunk
      @transcript.length
    end
  end

  def fresh?(last_pos)
    @transcript && @transcript.length > last_pos
  end

  def glean(stripped, last_pos)
    @mutex.synchronize do
      return last_pos unless ripe?(last_pos)

      chunk = @transcript_stripped[last_pos...@transcript_stripped.length]
      stripped << chunk
      @transcript_stripped.length
    end
  end

  def ripe?(last_pos)
    @transcript_stripped && @transcript_stripped.length > last_pos
  end

  def wild(output, pattern, timeout)
    stripped = ""
    loop do
      break if stop?(timeout, output, pattern, stripped)

      sleep 0.01
    end
    output
  end

  def stop?(timeout, output, pattern, stripped)
    Time.now >= timeout || take(output, pattern, stripped)
  end

  def take(output, pattern, stripped)
    chunk = fetch(@reader)
    return false if chunk.empty?

    log(chunk, output)
    stripped << strip(chunk)
    hit?(stripped, pattern)
  end

  def log(chunk, output)
    output << chunk
    @mutex ? guard(chunk) : plain(chunk)
  end

  def guard(chunk)
    @mutex.synchronize do
      record(chunk)
      paint(chunk)
      render(chunk)
    end
  end

  def record(chunk)
    @transcript << chunk if @transcript
  end

  def paint(chunk)
    @screen.absorb(chunk) if @screen
  end

  def render(chunk)
    stripped = encode(strip(chunk))
    @transcript_stripped << stripped if @transcript_stripped
  end

  def plain(chunk)
    record(chunk)
    paint(chunk)
    render(chunk)
  end
end
