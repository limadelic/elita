module Assert
  def table(tbl, output)
    cells(tbl).each { |c| cell(c, output) }
  end

  def cells(table)
    table.raw.flatten.map(&:strip).reject(&:empty?)
  end

  def cell(cell, output)
    if negated?(cell)
      content = cell[1..-2].strip
      content = content[1..-1].strip if content.start_with?(">")
      refute(content, output)
    else
      content = cell.start_with?(">") ? cell[1..-1].strip : cell
      assert(content, output)
    end
  end

  def negated?(cell)
    cell.start_with?("(") && cell.end_with?(")")
  end

  def assert(expected, output)
    expected.split.each { |w|
      output_lower = output.downcase
      w_lower = w.downcase
      unless output_lower.include?(w_lower)
        msg = "Expected '#{w}' in:\n#{output}"
        raise msg
      end
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
