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
    expected.split.each { |w|
      (output.downcase.include?(w.downcase) or raise("Expected '#{w}' in:\n#{output}"))
    }
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
