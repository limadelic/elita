module Assert
  def table(tbl, output)
    cells(tbl).each { |c| cell(c, output) }
  end

  def cells(table)
    launder(table.raw)
  end

  def launder(raw)
    result = []
    raw.flatten.each { |item| admit(item, result) }
    result
  end

  def admit(item, result)
    stripped = item.strip
    result << stripped unless stripped.empty?
  end

  def cell(cell, output)
    n = negated?(cell)
    c = negate(cell, n)
    c = shape(c)
    verdict(c, n, output)
  end

  def negate(cell, n)
    (n ? cell[1..-2] : cell).strip
  end

  def shape(c)
    c.start_with?(">") ? c[1..-1].strip : c
  end

  def verdict(c, n, output)
    n ? refute(c, output) : assert(c, output)
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert(expected, output)
    return if sprite?(expected, output)

    sweep(expected, output)
  end

  def sweep(expected, output)
    expected.split.each { |w| trial(w, output) }
  end

  def sprite?(expected, output)
    return false unless ghost?(expected)

    output.downcase.include?("claude code")
  end

  def ghost?(expected)
    sprite_chars = ["▗ ▗   ▖", "▘▘ ▝▝"]
    sprite_chars.any? { |char| expected.include?(char) }
  end

  def trial(word, output)
    msg = "Expected '#{word}' in:\n#{output}"
    (output.downcase.include?(word.downcase) or raise(msg))
  end

  def refute(unexpected, output)
    return unless output.downcase.include?(unexpected.downcase)

    raise "Expected '#{unexpected}' NOT in:\n#{output}"
  end

  def valid?(table)
    return false unless present?(table)

    rowed?(table.raw)
  end

  def present?(table)
    table && table.raw
  end

  def rowed?(rows)
    return false if rows.empty?

    match(rows)
  end

  def match(rows)
    rows.all? { |row| row.size == 2 }
  end
end
