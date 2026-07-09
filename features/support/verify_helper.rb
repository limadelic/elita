module VerifyHelper
  def verify_table(table, output)
    cells(table).each { |cell| verify_cell(cell, output) }
  end

  def reset
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def verify_lines(rows)
    reset unless @scenario_cursor
    deadline = timeout_deadline
    last_nudge = Time.now - 2

    loop do
      @folded_lines = prepare_lines
      matches = find_matches(rows, deadline)
      return update_cursor(matches) if matches

      last_nudge = break_or_retry(deadline, last_nudge)
    end
  end

  def nudge_pty
    return unless @writer
    @writer.write("\n")
    @writer.flush
  rescue IOError
  end

  def valid?(table)
    return false unless table && table.raw
    rows = table.raw
    return false if rows.empty?
    rows.all? { |row| row.size == 2 }
  end

  private

  def timeout_deadline
    timeout_secs = ENV["TAPE"] == "rec" ? 10 : (ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3)
    Time.now + timeout_secs
  end

  def prepare_lines
    tx = transcript
    tx = tx.force_encoding("UTF-8") if tx.respond_to?(:force_encoding)
    lines = tx.split("\n").map { |l| l.strip.force_encoding("UTF-8") rescue l.strip }.reject(&:empty?)
    fold(lines)
  end

  def find_matches(rows, deadline)
    all_found = true
    found_indices = []
    cursor = @scenario_cursor

    rows.each do |row|
      prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
      text = row[1].strip.downcase.force_encoding("UTF-8") rescue row[1].strip.downcase

      if match_row(prefix, text, cursor, found_indices)
        cursor = found_indices.last
      elsif Time.now >= deadline
        raise match_error(prefix, text)
      else
        all_found = false
        break
      end
    end

    all_found ? found_indices : nil
  end

  def match_row(prefix, text, cursor, matches)
    if prefix.empty?
      match_continuation(text, cursor, matches)
    else
      match_anchor(prefix, text, cursor, matches)
    end
  end

  def match_continuation(text, cursor, matches)
    return false if cursor >= @folded_lines.size

    line = clean_line(@folded_lines[cursor])
    _prefix, line_text = split(line)

    return false unless line_text
    return false unless matches_text?(text, line_text)

    matches << cursor + 1
    true
  end

  def match_anchor(prefix, text, cursor, matches)
    (@scenario_cursor...@folded_lines.size).each do |idx|
      line = clean_line(@folded_lines[idx])
      line_prefix, line_text = split(line)

      next unless line_prefix && line_text
      next unless line_prefix.include?(prefix)
      next unless matches_text?(text, line_text)

      matches << idx + 1
      return true
    end

    false
  end

  def clean_line(line)
    line.sub(/\A(?:\s*\w+>\s*)+/, "")
  end

  def normalize(text)
    text.downcase.gsub(/\s+/, "")
  end

  def matches_text?(want, have)
    want.empty? || have.downcase.include?(want) || normalize(have).include?(normalize(want))
  end

  def match_error(prefix, text)
    "No match for prefix='#{prefix}' text='#{text}'\n\nTranscript:\n#{transcript}"
  end

  def break_or_retry(deadline, last_nudge)
    if Time.now >= deadline
      raise "Timeout waiting for all rows to match.\n\nTranscript:\n#{transcript}"
    end

    drain_pty

    if ENV["TAPE"] != "rec" && Time.now - last_nudge >= 1.0
      nudge_pty
      last_nudge = Time.now
    end

    sleep 0.05
    last_nudge
  end

  def update_cursor(matches)
    @scenario_cursor = matches.max if matches.any?
  end

  def split(line)
    colon_idx = line.index(": ")
    equals_idx = line.index(" = ")

    return [line, line] unless colon_idx || equals_idx

    if colon_idx && !equals_idx
      [line[0...colon_idx], line[colon_idx + 2..-1]]
    elsif equals_idx && !colon_idx
      [line[0...equals_idx], line[equals_idx + 3..-1]]
    elsif colon_idx < equals_idx
      [line[0...colon_idx], line[colon_idx + 2..-1]]
    else
      [line[0...equals_idx], line[equals_idx + 3..-1]]
    end
  end

  def fold(lines)
    result = []
    idx = nil

    lines.each do |line|
      if log?(line) || board?(line)
        result << line
        idx = result.size - 1
      elsif idx && idx >= 0
        result[idx] << " " << line
      end
    end

    result
  end

  def board?(line)
    line.match?(/^[XO_\s]*\|[XO_\s]*\|[XO_\s]*$/) rescue false
  end

  def log?(line)
    emoji = line.match?(/^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/) rescue false
    save = line.match?(/^✏️\s+\w+.*=/) rescue false
    prompt_emoji = line.match?(/^\w+>\s+[\p{So}🀀-🿿]/) rescue false
    prompt = line.match?(/^\w+>$/) rescue false
    emoji || save || prompt_emoji || prompt
  end

  def cells(table)
    table.raw.flatten.map(&:strip).reject(&:empty?)
  end

  def verify_cell(cell, output)
    if negated?(cell)
      content = cell[1..-2].strip
      content = content[1..-1].strip if content.start_with?(">")
      refute_includes(content, output)
    else
      content = cell.start_with?(">") ? cell[1..-1].strip : cell
      assert_includes(content, output)
    end
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert_includes(expected, output)
    expected.split.each { |w| raise "Expected '#{w}' in:\n#{output}" unless output.downcase.include?(w.downcase) }
  end

  def refute_includes(unexpected, output)
    raise "Expected '#{unexpected}' NOT in:\n#{output}" if output.downcase.include?(unexpected.downcase)
  end
end

World(VerifyHelper)
