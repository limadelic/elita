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
    timeout = snap_deadline()
    snap_lines = wait_for_screen_settle(timeout)
    golden_lines = tbl.raw.map { |row| row[0].rstrip }
    return if block_found?(golden_lines, snap_lines)

    raise snap_error(golden_lines, snap_lines)
  end

  def snap_error(golden_lines, snap_lines)
    snap_detail = snap_lines.each_with_index.map { |l, i| "  [#{i}] len=#{l.length}" }.join("\n")
    "Expected snap block (#{golden_lines.length} lines):\nActual snap (#{snap_lines.length} lines):\n#{snap_detail}"
  end

  def screen_lines
    screen_render = @screen ? @screen.to_s : ""
    lines = screen_render.split("\n")
    trim_edges(lines)
  end

  def trim_edges(lines)
    lines.shift while lines.first&.empty?
    lines.pop while lines.last&.empty?
    lines
  end

  def wait_for_screen_settle(deadline)
    loop do
      current = screen_lines
      sleep 3
      next_frame = screen_lines

      return current if current == next_frame
      raise "Timeout waiting for screen settle" if Time.now > deadline
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def block_found?(golden_lines, snap_lines)
    return true if golden_lines.empty?

    (0..snap_lines.length - golden_lines.length).each do |start_idx|
      block = snap_lines[start_idx, golden_lines.length]
      normalized_block = block.map { |l| fix_and_normalize(l) }
      normalized_golden = golden_lines.map { |l| fix_and_normalize(l) }
      return true if normalized_block == normalized_golden
    end
    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  def fix_and_normalize(line)
    # Simple normalization: just rstrip
    line.rstrip
  end

  def snap_deadline
    Time.now + 30
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
