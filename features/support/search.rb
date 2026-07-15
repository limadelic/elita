module Search
  PATTERNS = [
    /^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/,
    /^✏️\s+\w+.*=/,
    /^\w+>\s+[\p{So}🀀-🿿]/,
    /^\w+>$/
  ].freeze

  def verify(rows)
    init unless @scenario_cursor
    deadline = deadline()
    cycle(rows, deadline)
  end

  def init
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def cycle(rows, deadline)
    last_sent = Time.now - 2
    while !search(rows, normalize(transcript), deadline, transcript)
      last_sent = tick(last_sent)
      sleep 0.05
    end
  end

  def tick(last_sent)
    return last_sent if ENV["TAPE"] == "rec" || Time.now - last_sent < 1.0

    drain; nudge; Time.now
  end

  def search(rows, folded_lines, deadline, tx)
    found_indices = hit(rows, folded_lines, deadline, tx)
    return nil unless found_indices

    @scenario_cursor = found_indices.max if found_indices.any?
    found_indices
  end

  def hit(rows, folded_lines, deadline, tx)
    rows.each_with_object([]) do |row, acc|
      idx = find(row, folded_lines, deadline, tx)
      return nil unless idx

      acc << idx
    end
  end

  def find(row, folded_lines, deadline, tx)
    prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
    downtext = row[1].strip.downcase
    text = downtext.force_encoding("UTF-8") rescue downtext
    scan(folded_lines, prefix, text) || fail(prefix, text, deadline, tx)
  end

  def scan(folded_lines, prefix, text)
    (@scenario_cursor...folded_lines.size).each do |idx|
      return idx + 1 if match?(folded_lines[idx], prefix, text)
    end
    nil
  end

  def fail(prefix, text, deadline, tx)
    return nil if Time.now < deadline

    msg = "No match for prefix='#{prefix}' text='#{text}'"
    raise msg << "\n\nTranscript:\n#{tx}"
  end

  def split(line)
    seps = [[line.index(" | "), 3], [line.index(": "), 2], [line.index(" = "), 3]]
    valid_seps = seps.select { |idx, _| idx }.min_by { |idx, _| idx }
    return [line, line] unless valid_seps

    first_idx, skip_len = valid_seps
    [line[0...first_idx], line[first_idx + skip_len..-1]]
  end

  def match?(folded_line, want_prefix, want_text)
    line = folded_line.sub(/\A(?:\s*\w+>\s*)+/, "")
    prefix, text = split(line)
    return false unless prefix && text

    [
      prefix.include?(want_prefix),
      want_text.empty? ||
        text.downcase.include?(want_text) ||
        text.downcase.gsub(/\s+/, "").include?(want_text.gsub(/\s+/, ""))
    ].all?
  end

  def deadline
    timeout = ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3
    timeout = 300 if ENV["TAPE"] == "rec"
    Time.now + timeout
  end

  def normalize(transcript)
    tx = (transcript.dup.force_encoding("UTF-8") rescue transcript)
    lines = tx.split("\n").map { |l|
      l.strip.force_encoding("UTF-8") rescue l.strip
    }.reject(&:empty?)
    fold(lines)
  end

  def fold(lines)
    lines.each_with_object([]) { |line, result| fold_line(line, result) }
  end

  def fold_line(line, result)
    is_log = check_log_pattern(line)
    add_or_append(line, result, is_log)
  end

  def check_log_pattern(line)
    PATTERNS.any? { |p| (line.match?(p) rescue false) }
  end

  def add_or_append(line, result, is_log)
    return result << line if is_log
    return if result.empty?

    result[-1] << " " << line
  end

  def nudge
    return unless @writer

    @writer.write("\n")
    @writer.flush
  rescue IOError
  end
end
