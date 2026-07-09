module VerifyHelper
  def table(tbl, output)
    cells(tbl).each { |c| cell(c, output) }
  end

  def init
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def verify(rows)
    init unless @scenario_cursor
    deadline = deadline()
    verify_loop(rows, deadline)
  end

  def verify_loop(rows, deadline)
    last_newline_sent = Time.now - 2
    loop do
      return if search(rows, normalize(transcript), deadline, transcript)
      drain
      nudge_if_needed(last_newline_sent)
      last_newline_sent = Time.now if timing?(last_newline_sent)
      sleep 0.05
    end
  end

  def nudge_if_needed(last_sent)
    return unless timing?(last_sent)
    nudge
  end

  def search(rows, folded_lines, deadline, tx)
    found_indices = []

    rows.each do |row|
      want_prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
      want_text = row[1].strip.downcase
      want_text = want_text.force_encoding("UTF-8") rescue want_text
      found = false

      (@scenario_cursor...folded_lines.size).each do |idx|
        if match?(folded_lines[idx], want_prefix, want_text)
          found_indices << idx + 1
          found = true
          break
        end
      end

      unless found
        if pending?(deadline)
          return nil
        else
          msg = "No match for prefix='#{want_prefix}' text='#{want_text}'"
          msg << "\n\nTranscript:\n#{tx}"
          raise msg
        end
      end
    end

    @scenario_cursor = found_indices.max if found_indices.any?
    found_indices
  end

  def nudge
    return unless @writer

    @writer.write("\n")
    @writer.flush
  rescue IOError
    # PTY might be closed, ignore
  end

  def valid?(table)
    return false unless table && table.raw

    rows = table.raw
    return false if rows.empty?

    rows.all? { |row| row.size == 2 }
  end

  private

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
      /^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/, # emoji + space + letter
      /^✏️\s+\w+.*=/, # pencil + word + =
      /^\w+>\s+[\p{So}🀀-🿿]/, # prompt + emoji
      /^\w+>$/ # just prompt
    ]
    patterns.any? { |p| (line.match?(p) rescue false) }
  end

  def cells(table)
    table.raw.flatten.map(&:strip).reject(&:empty?)
  end

  def cell(cell, output)
    if negated?(cell)
      content = cell[1..-2].strip
      content = content[1..-1].strip if content.start_with?(">")
      refute(content, output)
    else
      content = cell.start_with?(">") ? cell[1..-1].strip : cell
      assert(content, output)
    end
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert(expected, output)
    expected.split.each { |w|
      output_lower = output.downcase
      w_lower = w.downcase
      unless output_lower.include?(w_lower)
        msg = "Expected '#{w}' in:\n#{output}"
        raise msg
      end
    }
  end

  def refute(unexpected, output)
    output_lower = output.downcase
    unexpected_lower = unexpected.downcase
    if output_lower.include?(unexpected_lower)
      msg = "Expected '#{unexpected}' NOT in:\n#{output}"
      raise msg
    end
  end
end

World(VerifyHelper)
