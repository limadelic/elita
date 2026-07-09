module Search
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
    loop do
      tx = transcript
      return if search(rows, normalize(tx), deadline, tx)

      drain; (nudge; last_sent = Time.now) if timing?(last_sent)
      sleep 0.05
    end
  end

  def search(rows, folded_lines, deadline, tx)
    found_indices = rows.each_with_object([]) do |row, acc|
      idx = find(row, folded_lines, deadline, tx)
      return nil unless idx

      acc << idx
    end
    @scenario_cursor = found_indices.max if found_indices.any?
    found_indices
  end

  def find(row, folded_lines, deadline, tx)
    prefix, text = parse(row)
    scan(
      folded_lines, prefix,
      text
    ) || fail(prefix, text, deadline, tx)
  end

  def parse(row)
    prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
    text = row[1].strip.downcase
    text = text.force_encoding("UTF-8") rescue text
    [prefix, text]
  end

  def scan(folded_lines, prefix, text)
    (@scenario_cursor...folded_lines.size).each do |idx|
      return idx + 1 if match?(folded_lines[idx], prefix, text)
    end
    nil
  end

  def fail(prefix, text, deadline, tx)
    return nil if pending?(deadline)

    msg = "No match for prefix='#{prefix}' text='#{text}'"
    msg << "\n\nTranscript:\n#{tx}"
    raise msg
  end

  def pending?(deadline)
    Time.now < deadline
  end

  def timing?(last_sent)
    ENV["TAPE"] != "rec" && Time.now - last_sent >= 1.0
  end

  def split(line)
    case [line.index(": "), line.index(" = ")]
    in [c, e] if c && (!e || c < e)
      [line[0...c], line[c + 2..-1]]
    in [_, e] if e
      [line[0...e], line[e + 3..-1]]
    else
      [line, line]
    end
  end

  def match?(folded_line, want_prefix, want_text)
    line = folded_line.sub(/\A(?:\s*\w+>\s*)+/, "")
    prefix, text = split(line)
    return false unless prefix && text

    prefix_matches = prefix.include?(want_prefix)
    text_matches = want_text.empty? ||
      text.downcase.include?(want_text) ||
      text.downcase.gsub(/\s+/, "").include?(want_text.gsub(/\s+/, ""))
    prefix_matches && text_matches
  end

  def deadline
    timeout = ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3
    timeout = 10 if ENV["TAPE"] == "rec"
    Time.now + timeout
  end

  def normalize(transcript)
    tx = transcript
    tx = tx.force_encoding("UTF-8") if tx.respond_to?(:force_encoding)
    lines = tx.split("\n").map { |l|
      l.strip.force_encoding("UTF-8") rescue l.strip
    }.reject(&:empty?)
    fold(lines)
  end

  def fold(lines)
    lines.each_with_object([]) do |line, result|
      if log?(line)
        result << line
      elsif result.any?
        result[-1] << " " << line
      end
    end
  end

  def log?(line)
    patterns = [
      /^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/,
      /^✏️\s+\w+.*=/,
      /^\w+>\s+[\p{So}🀀-🿿]/,
      /^\w+>$/
    ]
    patterns.any? { |p| (line.match?(p) rescue false) }
  end

  def nudge
    return unless @writer

    @writer.write("\n")
    @writer.flush
  rescue IOError
  end
end
