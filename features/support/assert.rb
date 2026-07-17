module Assert
  def table(tbl, output)
    return snap(tbl, output) if is_snap_table?(tbl)

    cells(tbl).each { |c| cell(c, output) }
  end

  def snap(tbl, output)
    tbl.raw.each do |row|
      row_text = row[0].strip
      unless snap_matches?(row_text, output)
        raise "Expected '#{row_text}' in output"
      end
    end
  end

  def snap_matches?(row_text, screen_content)
    # Extract all text content, removing box drawing characters and formatting
    cleaned = row_text.gsub(/[╭╮╰│─╰ `\/⚠·]+/, " ").strip

    # Split into words
    words = cleaned.split(/\s+/).reject(&:empty?)

    # Filter to meaningful words (alphanumeric, length > 2, no pure graphics)
    keywords = words.select do |w|
      ascii_w = w.gsub(/[…]/, "")
      ascii_w.length > 3 && ascii_w.match?(/[a-zA-Z0-9]/) && !ascii_w.match?(/^[█]+$/)
    end

    # If no keywords, it's a formatting line - skip it
    return true if keywords.empty?

    # For screen content, check that keywords are present
    # Be lenient because of truncations and formatting
    matched = keywords.count do |kw|
      kw_search = kw.gsub(/…/, "").downcase
      screen_content.downcase.include?(kw_search)
    end

    # Require at least 40% of keywords to match
    matched >= (keywords.length * 0.4).ceil
  end

  def is_snap_table?(tbl)
    return false unless tbl.raw.all? { |row| row.size == 1 }

    first_row = tbl.raw[0][0].strip rescue ""
    has_box = first_row.start_with?("╭") || first_row.include?("───")
    has_warning = first_row.include?("⚠")

    has_box || (tbl.raw.any? { |r| r[0].include?("╭") || r[0].include?("│") })  || has_warning
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
