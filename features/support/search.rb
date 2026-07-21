module Search
  PATTERNS = [
    /^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/,
    /^✏️\s+\w+.*=/,
    /^\w+>\s+[\p{So}🀀-🿿]/,
    /^\w+>$/
  ].freeze

  def verify(rows)
    init unless @scenario_cursors
    deadline = bound()
    hunt(rows, deadline)
  rescue Timeout::Error, Timeout::ExitException => e
    raise_with_screen_dump(e)
  end

  def init
    @scenario_cursors = {}
    @folded_lines = nil
  end

  def hunt(rows, deadline)
    last_sent = Time.now - 2
    while !search(rows, normalize(transcript), deadline)
      last_sent = tick(last_sent)
      sleep 0.05
    end
  end

  def tick(last_sent)
    return last_sent if ENV["TAPE"] == "rec" || Time.now - last_sent < 1.0

    drain; nudge; Time.now
  end

  def search(rows, folded_lines, deadline)
    found_indices = hit(rows, folded_lines, deadline)
    return nil unless found_indices

    if found_indices.any?
      @scenario_cursors[@current] = found_indices.max
    end
    found_indices
  end

  def hit(rows, folded_lines, deadline)
    rows.each_with_object([]) do |row, acc|
      idx = find(row, folded_lines, deadline)
      return nil unless idx

      acc << idx
    end
  end

  def find(row, folded_lines, deadline)
    prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
    prefix = strip_variation_selectors(prefix)
    downtext = row[1].strip.downcase
    text = downtext.force_encoding("UTF-8") rescue downtext
    text = strip_variation_selectors(text)
    scan(folded_lines, prefix, text) || fail(prefix, text, deadline, folded_lines)
  end

  def scan(folded_lines, prefix, text)
    cursor = @scenario_cursors[@current] ||= 0
    (cursor...folded_lines.size).each do |idx|
      return idx + 1 if match?(folded_lines[idx], prefix, text)
    end
    nil
  end

  def fail(prefix, text, deadline, folded_lines)
    return nil if Time.now < deadline

    msg = "No match for prefix='#{prefix}' text='#{text}'"
    screen_dump = folded_lines.last(40).join("\n")
    raise msg << "\n\nScreen:\n#{screen_dump}"
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

  def bound
    timeout = ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3
    timeout = 300 if ENV["TAPE"] == "rec"
    Time.now + timeout
  end

  def normalize(transcript)
    tx = (transcript.dup.force_encoding("UTF-8") rescue transcript)
    tx = tx.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
    tx = strip_variation_selectors(tx)
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

  def strip_variation_selectors(text)
    text.gsub("\u{FE0F}", "")
  end

  def raise_with_screen_dump(e)
    folded = normalize(transcript)
    screen_dump = folded.last(40).join("\n")
    error_msg = "#{e.message}\n\nScreen:\n#{screen_dump}"
    raise RuntimeError, error_msg
  end
end
