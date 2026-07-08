module VerifyHelper
  def verify_table(table, output)
    cells(table).each { |cell| verify_cell(cell, output) }
  end

  def verify_lines(rows)
    tx = transcript
    lines = tx.split("\n").map(&:strip).reject(&:empty?)
    cursor = 0

    rows.each do |row|
      want_prefix = row[0].strip
      want_text = row[1].strip.downcase
      found = false

      (cursor...lines.size).each do |idx|
        line = lines[idx]

        if line.include?(": ")
          line_prefix, line_text = line.split(": ", 2)
          prefix_match = line_prefix == want_prefix
          text_match = want_text.empty? || line_text.downcase.include?(want_text)

          if prefix_match && text_match
            cursor = idx + 1
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
