module VerifyHelper
  def verify_table(table, output)
    cells(table).each { |cell| verify_cell(cell, output) }
  end

  private

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
