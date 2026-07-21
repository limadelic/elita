module Search
  include Parse

  def verify(rows)
    @scenario_cursors ||= {}
    shield(rows)
  end

  def shield(rows)
    hunt(rows, bound())
  rescue Timeout::Error, Timeout::ExitException => e
    dump(e)
  end

  def hunt(rows, deadline)
    last_sent = Time.now - 2
    while !search(rows, normalize(transcript), deadline)
      last_sent = tick(last_sent)
      sleep 0.05
    end
  end

  def tick(last_sent)
    return last_sent if wait?(last_sent)

    drain
    nudge
    Time.now
  end

  def wait?(last_sent)
    ENV["TAPE"] == "rec" || Time.now - last_sent < 1.0
  end

  def search(rows, folded_lines, deadline)
    found_indices = hit(rows, folded_lines, deadline)
    return nil unless found_indices

    bank(found_indices)
  end

  def bank(found_indices)
    @scenario_cursors[@current] = found_indices.max if found_indices.any?
    found_indices
  end

  def hit(rows, folded_lines, deadline)
    indices = gather(rows, folded_lines, deadline)
    complete?(indices) ? indices : nil
  end

  def gather(rows, folded_lines, deadline)
    rows.map { |row| find(row, folded_lines, deadline) }
  end

  def complete?(indices)
    indices.count == indices.compact.count
  end

  def find(row, folded_lines, deadline)
    prefix = prefix(row[0])
    text = text(row[1])
    scan(folded_lines, prefix, text) || fail(prefix, text, deadline, folded_lines)
  end

  def prefix(raw)
    prefix = safe_encode(raw.strip)
    strip_variation_selectors(prefix)
  end

  def text(raw)
    text = safe_encode(raw.strip.downcase)
    strip_variation_selectors(text)
  end

  def scan(folded_lines, prefix, text)
    cursor = @scenario_cursors[@current] ||= 0
    probe(folded_lines, prefix, text, cursor)
  end

  def probe(folded_lines, prefix, text, cursor)
    idx = locate(folded_lines, prefix, text, cursor)
    idx ? idx + 1 : nil
  end

  def locate(folded_lines, prefix, text, cursor)
    (cursor...folded_lines.size).find { |idx| match?(folded_lines[idx], prefix, text) }
  end

  def fail(prefix, text, deadline, folded_lines)
    return nil if Time.now < deadline

    msg = "No match for prefix='#{prefix}' text='#{text}'"
    screen_dump = folded_lines.last(40).join("\n")
    raise msg << "\n\nScreen:\n#{screen_dump}"
  end

  def split(line)
    sep = sep(line)
    sep ? slice(line, sep) : [line, line]
  end

  def sep(line)
    seps = seps(line)
    pick(seps)
  end

  def seps(line)
    [[line.index(" | "), 3], [line.index(": "), 2], [line.index(" = "), 3]]
  end

  def pick(seps)
    prune(seps).min_by { |idx, _| idx }
  end

  def prune(seps)
    seps.select { |idx, _| idx }
  end

  def slice(line, sep)
    first_idx, skip_len = sep
    [line[0...first_idx], line[first_idx + skip_len..-1]]
  end

  def match?(folded_line, want_prefix, want_text)
    prefix, text = parts(folded_line)
    return false unless both?(prefix, text)

    ok?(prefix, want_prefix, text, want_text)
  end

  def parts(folded_line)
    line = folded_line.sub(/\A(?:\s*\w+>\s*)+/, "")
    split(line)
  end

  def both?(prefix, text)
    prefix && text
  end

  def ok?(prefix, want_prefix, text, want_text)
    fit?(prefix, want_prefix) ? texts?(text, want_text) : false
  end

  def fit?(prefix, want)
    prefix.include?(want)
  end

  def texts?(text, want)
    return true if want.empty?

    normalized = text.downcase
    compact = normalized.gsub(/\s+/, "")
    want_compact = want.gsub(/\s+/, "")
    exact?(normalized, want, compact, want_compact)
  end

  def exact?(normalized, want, compact, want_compact)
    return true if normalized.include?(want)

    compact.include?(want_compact)
  end

  def bound
    Time.now + timeout
  end

  private

  def timeout
    recording? ? 300 : leash
  end

  def recording?
    ENV["TAPE"] == "rec"
  end

  def leash
    ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3
  end

  def nudge
    return unless @writer

    flush
  end

  def flush
    @writer.write("\n")
    @writer.flush
  rescue IOError
  end

  def dump(e)
    folded = normalize(transcript)
    screen = folded.last(40).join("\n")
    error_msg = "#{e.message}\n\nScreen:\n#{screen}"
    raise RuntimeError, error_msg
  end
end
