module VerifyHelper
  def validate(table, output)
    cells(table).each { |cell| check(cell, output) }
  end

  def reset
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def lines(rows)
    reset unless @scenario_cursor
    deadline = self.deadline
    last_nudge = Time.now - 2

    loop do
      @folded_lines = squeeze
      matches = search(rows, deadline)
      return advance(matches) if matches

      last_nudge = persist(deadline, last_nudge)
    end
  end

  def nudge
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

  def deadline
    secs = ENV["TAPE"] == "rec" ? 10 : (ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3)
    Time.now + secs
  end

  def squeeze
    tx = transcript
    tx = tx.force_encoding("UTF-8") if tx.respond_to?(:force_encoding)
    lines = tx.split("\n").map { |l|
      l.strip.force_encoding("UTF-8") rescue l.strip
    }.reject(&:empty?)
    fold(lines)
  end

  def search(rows, deadline)
    all_found = true
    found_indices = []
    cursor = @scenario_cursor

    rows.each do |row|
      prefix = safe(row[0].strip)
      text = safe(row[1].strip.downcase)

      if row(prefix, text, cursor, found_indices)
        cursor = found_indices.last
      elsif Time.now >= deadline
        raise error(prefix, text)
      else
        all_found = false
        break
      end
    end

    all_found ? found_indices : nil
  end

  def row(prefix, text, cursor, matches)
    if prefix.empty?
      scan(text, cursor, matches)
    else
      anchor(prefix, text, cursor, matches)
    end
  end

  def scan(text, cursor, matches)
    return false if cursor >= @folded_lines.size

    line = scrub(@folded_lines[cursor])
    _prefix, line_text = split(line)

    return false unless line_text
    return false unless match?(text, line_text)

    matches << cursor + 1
    true
  end

  def anchor(prefix, text, cursor, matches)
    (@scenario_cursor...@folded_lines.size).each do |idx|
      line = scrub(@folded_lines[idx])
      line_prefix, line_text = split(line)

      next unless line_prefix && line_text
      next unless line_prefix.include?(prefix)
      next unless match?(text, line_text)

      matches << idx + 1
      return true
    end

    false
  end

  def scrub(line)
    line.sub(/\A(?:\s*\w+>\s*)+/, "")
  end

  def normalize(text)
    text.downcase.gsub(/\s+/, "")
  end

  def safe(text)
    text.force_encoding("UTF-8")
  rescue
    text
  end

  def match?(want, have)
    want.empty? ||
      have.downcase.include?(want) ||
      normalize(have).include?(normalize(want))
  end

  def error(prefix, text)
    msg = "No match for prefix='#{prefix}' text='#{text}'"
    "#{msg}\n\nTranscript:\n#{transcript}"
  end

  def persist(deadline, last_nudge)
    if Time.now >= deadline
      msg = "Timeout waiting for all rows to match."
      raise "#{msg}\n\nTranscript:\n#{transcript}"
    end

    drain

    if ENV["TAPE"] != "rec" && Time.now - last_nudge >= 1.0
      nudge
      last_nudge = Time.now
    end

    sleep 0.05
    last_nudge
  end

  def advance(matches)
    @scenario_cursor = matches.max if matches.any?
  end

  def split(line)
    colon_idx = line.index(": ")
    equals_idx = line.index(" = ")
    return [line, line] unless colon_idx || equals_idx

    choose(line, colon_idx, equals_idx)
  end

  def choose(line, c_idx, e_idx)
    pick_idx = c_idx && !e_idx ? c_idx : (e_idx && !c_idx ? e_idx : (c_idx < e_idx ? c_idx : e_idx))
    offset = (pick_idx == c_idx) ? 2 : 3
    [line[0...pick_idx], line[pick_idx + offset..-1]]
  end

  def fold(lines)
    result = []
    idx = nil
    lines.each { |line| idx = mark(result, line, idx) }
    result
  end

  def mark(result, line, idx)
    if log?(line) || board?(line)
      result << line
      return result.size - 1
    end
    result[idx] << " " << line if idx && idx >= 0
    idx
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

  def check(cell, output)
    if negated?(cell)
      refute(extract(cell), output)
    else
      assert(extract(cell), output)
    end
  end

  def extract(cell)
    content = negated?(cell) ? cell[1..-2].strip : cell
    content.start_with?(">") ? content[1..-1].strip : content
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert(expected, output)
    expected.split.each do |w|
      next if output.downcase.include?(w.downcase)

      msg = "Expected '#{w}' in:\n#{output}"
      raise msg
    end
  end

  def refute(unexpected, output)
    return unless output.downcase.include?(unexpected.downcase)

    msg = "Expected '#{unexpected}' NOT in:\n#{output}"
    raise msg
  end
end

World(VerifyHelper)
