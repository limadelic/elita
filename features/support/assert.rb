module Assert
  def table(tbl, output)
    return snap(tbl) if single_column_table?(tbl)

    cells(tbl).each { |c| cell(c, output) }
  end

  def single_column_table?(tbl)
    return false unless tbl && tbl.raw && tbl.raw.any?
    tbl.raw.all? { |row| row.size == 1 }
  end

  def snap(tbl)
    # Get the screen render
    screen_render = @screen ? @screen.to_s : ""
    snap_lines = screen_render.split("\n")
    snap_lines.shift while snap_lines.first&.empty?
    snap_lines.pop while snap_lines.last&.empty?

    golden_lines = tbl.raw.map { |row| row[0].rstrip }

    # Find golden lines as contiguous block in snap lines
    unless block_found?(golden_lines, snap_lines)
      msg = "Expected snap block:\n#{golden_lines.join("\n")}\n\nIn:\n#{snap_lines.join("\n")}"
      raise msg
    end
  end

  def block_found?(golden_lines, snap_lines)
    return true if golden_lines.empty?

    (0..snap_lines.length - golden_lines.length).each do |start_idx|
      block = snap_lines[start_idx, golden_lines.length]
      # Normalize both screen lines and golden lines to handle encoding issues
      normalized_block = block.map { |l| fix_and_normalize(l) }
      normalized_golden = golden_lines.map { |l| fix_and_normalize(l) }
      return true if normalized_block == normalized_golden
    end
    false
  end

  def fix_and_normalize(line)
    # Simple normalization: just rstrip
    line.rstrip
  end

  def cells(table)
    table.raw.flatten.map(&:strip).reject(&:empty?)
  end

  def cell(cell, output)
    n = negated?(cell)
    c = (n ? cell[1..-2] : cell).strip
    c = c[1..-1].strip if c.start_with?(">")
    (n ? refute : method(:assert)).call(c, output)
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert(expected, output)
    expected.split.each { |w| check_word(w, output) }
  end

  def check_word(word, output)
    msg = "Expected '#{word}' in:\n#{output}"
    (output.downcase.include?(word.downcase) or raise(msg))
  end

  def refute(unexpected, output)
    return unless output.downcase.include?(unexpected.downcase)

    raise "Expected '#{unexpected}' NOT in:\n#{output}"
  end

  def valid?(table)
    return false unless table && table.raw

    rows = table.raw
    return false if rows.empty?

    rows.all? { |row| row.size == 2 }
  end
end
