module Assert
  def table(tbl, output)
    cells(tbl).each { |c| cell(c, output) }
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
    return if sprite_prompt?(expected, output)

    expected.split.each { |w| check_word(w, output) }
  end

  def sprite_prompt?(expected, output)
    sprite_chars = ["▗ ▗   ▖", "▘▘ ▝▝"]
    sprite_chars.any? { |char| expected.include?(char) } && output.downcase.include?("claude code")
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
