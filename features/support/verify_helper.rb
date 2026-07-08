module VerifyHelper
  def verify_table(table, output)
    cells(table).each { |cell| verify_cell(cell, output) }
  end

  def initialize_scenario_cursor
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def verify_lines(rows)
    initialize_scenario_cursor unless @scenario_cursor
    tx = transcript
    tx = tx.force_encoding("UTF-8") if tx.respond_to?(:force_encoding)
    lines = tx.split("\n").map { |l| l.strip.force_encoding("UTF-8") rescue l.strip }.reject(&:empty?)
    @folded_lines = fold_continuation_lines(lines)

    rows.each do |row|
      want_prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
      want_text = row[1].strip.downcase.force_encoding("UTF-8") rescue row[1].strip.downcase
      found = false

      (@scenario_cursor...@folded_lines.size).each do |idx|
        full_line = @folded_lines[idx]
        line_prefix, line_text = split_line(full_line)

        if line_prefix && line_text
          prefix_match = line_prefix == want_prefix
          text_match = want_text.empty? || line_text.downcase.include?(want_text) || line_text.downcase.gsub(/\s+/, "").include?(want_text.gsub(/\s+/, ""))

          if prefix_match && text_match
            @scenario_cursor = idx + 1
            found = true
            break
          end
        end
      end

      unless found
        raise "No match for prefix='#{want_prefix}' text='#{want_text}'\n\nTranscript:\n#{tx}"
      end
    end
  end

  def is_verify_table?(table)
    return false unless table && table.raw
    rows = table.raw
    return false if rows.empty?
    rows.all? { |row| row.size == 2 }
  end

  private

  def split_line(line)
    colon_idx = line.index(": ")
    equals_idx = line.index(" = ")

    if colon_idx && equals_idx
      if colon_idx < equals_idx
        [line[0...colon_idx], line[colon_idx + 2..-1]]
      else
        [line[0...equals_idx], line[equals_idx + 3..-1]]
      end
    elsif colon_idx
      [line[0...colon_idx], line[colon_idx + 2..-1]]
    elsif equals_idx
      [line[0...equals_idx], line[equals_idx + 3..-1]]
    else
      [nil, nil]
    end
  end

  def fold_continuation_lines(lines)
    result = []
    current = nil

    lines.each do |line|
      if log_line?(line)
        result << line
        current = result.size - 1
      elsif current && current >= 0
        result[current] << " " << line
      end
    end

    result
  end

  def log_line?(line)
    # Match log lines: emoji followed by space and letters/emoji (agent/system markers)
    # Exclude lines starting with emoji but followed by decorative chars like * ✅
    line.match?(/^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/) rescue false
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
