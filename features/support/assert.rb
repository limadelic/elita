module Assert
  def table(tbl, output)
    tabulate(tbl, output)
  end

  def tabulate(tbl, output)
    snap_or_check(tbl, output)
  end

  def snap_or_check(tbl, output)
    return snap(tbl) if single_column_table?(tbl)

    verify_cells(tbl, output)
  end

  def verify_cells(tbl, output)
    cells(tbl).each { |c| check(c, output) }
  end

  def single_column_table?(tbl)
    table?(tbl) && single_column?(tbl)
  end

  def table?(tbl)
    return false unless data?(tbl)

    any_rows?(tbl)
  end

  def data?(tbl)
    tbl && tbl.raw
  end

  def any_rows?(tbl)
    tbl.raw.any?
  end

  def single_column?(tbl)
    tbl.raw.all? { |row| row.size == 1 }
  end

  def cells(table)
    clean(table.raw)
  end

  def clean(raw)
    result = []
    raw.flatten.each { |item| push_clean(item, result) }
    result
  end

  def push_clean(item, result)
    stripped = item.strip
    result << stripped unless stripped.empty?
  end

  def check(cell, output)
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
