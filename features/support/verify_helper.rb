module VerifyHelper
  def table(tbl, output)
    cells(tbl).each { |c| cell(c, output) }
  end

  def init
    @scenario_cursor = 0
    @folded_lines = nil
  end

  def verify(rows)
    init unless @scenario_cursor
    deadline = deadline()
    last_newline_sent = Time.now - 2 # Allow immediately first send

    loop do
      tx = transcript
      tx = tx.force_encoding("UTF-8") if tx.respond_to?(:force_encoding)
      lines = tx.split("\n").map { |l|
        l.strip.force_encoding("UTF-8") rescue l.strip
      }.reject(&:empty?)
      @folded_lines = fold(lines)

      all_found = true
      found_indices = []

      rows.each do |row|
        want_prefix = row[0].strip.force_encoding("UTF-8") rescue row[0].strip
        want_text = row[1].strip.downcase.force_encoding("UTF-8") rescue row[1].strip.downcase
        found = false

        (@scenario_cursor...@folded_lines.size).each do |idx|
          full_line = @folded_lines[idx]
          full_line = full_line.sub(/\A(?:\s*\w+>\s*)+/, "")
          line_prefix, line_text = split(full_line)

          if line_prefix && line_text
            prefix_match = line_prefix.include?(want_prefix)
            text_match = want_text.empty? || line_text.downcase.include?(want_text) || line_text.downcase.gsub(
              /\s+/, ""
            ).include?(want_text.gsub(/\s+/, ""))

            if prefix_match && text_match
              found_indices << idx + 1
              found = true
              break
            end
          end
        end

        unless found
          if Time.now < deadline
            all_found = false
            break
          else
            raise "No match for prefix='#{want_prefix}' text='#{want_text}'\n\nTranscript:\n#{tx}"
          end
        end
      end

      if all_found
        # Only update cursor if all rows were found
        @scenario_cursor = found_indices.max if found_indices.any?
        return
      end

      if Time.now >= deadline
        raise "Timeout waiting for all rows to match.\n\nTranscript:\n#{transcript}"
      end

      drain

      # After ~1s without a match, nudge PTY with newline to flush cascade output (replay only)
      if ENV["TAPE"] != "rec" && Time.now - last_newline_sent >= 1.0
        nudge
        last_newline_sent = Time.now
      end

      sleep 0.05
    end
  end

  def nudge
    return unless @writer

    @writer.write("\n")
    @writer.flush
  rescue IOError
    # PTY might be closed, ignore
  end

  def valid?(table)
    return false unless table && table.raw

    rows = table.raw
    return false if rows.empty?

    rows.all? { |row| row.size == 2 }
  end

  private

  def split(line)
    colon_idx = line.index(": ")
    equals_idx = line.index(" = ")

    if colon_idx && equals_idx
      if colon_idx < equals_idx
        [line[0...colon_idx], line[colon_idx + 2..-1]]
      else
        [line[0...equals_idx], line[equals_idx + 3..-1]]
      end
    elsif colon_idx
      [line[0...colon_idx], line[colon_idx + 2..-1]]
    elsif equals_idx
      [line[0...equals_idx], line[equals_idx + 3..-1]]
    else
      [line, line]
    end
  end

  def deadline
    timeout = ENV["GITHUB_ACTIONS"] == "true" ? 60 : 3
    timeout = 10 if ENV["TAPE"] == "rec"
    Time.now + timeout
  end

  def fold(lines)
    result = []
    current = nil

    lines.each_with_index do |line, input_idx|
      is_log = log?(line)
      if is_log
        result << line
        current = result.size - 1
      elsif current && current >= 0
        result[current] << " " << line
      end
    end

    result
  end

  def log?(line)
    # Match log lines: emoji followed by space and letters/emoji (agent/system markers)
    # OR match prompt lines: word characters followed by > (with or without emoji after)
    # OR match standalone prompts: word characters followed by >
    # OR match scenario save rows: ✏️ emoji followed by name and "="
    # Exclude lines starting with emoji but followed by decorative chars like * ✅
    is_emoji_line = line.match?(/^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/) rescue false
    is_scenario_save = line.match?(/^✏️\s+\w+.*=/) rescue false
    is_prompt_with_emoji = line.match?(/^\w+>\s+[\p{So}🀀-🿿]/) rescue false
    is_standalone_prompt = line.match?(/^\w+>$/) rescue false
    is_emoji_line || is_scenario_save || is_prompt_with_emoji || is_standalone_prompt
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
      raise "Expected '#{w}' in:\n#{output}" unless output.downcase.include?(w.downcase)
    }
  end

  def refute(unexpected, output)
    raise "Expected '#{unexpected}' NOT in:\n#{output}" if output.downcase.include?(unexpected.downcase)
  end
end

World(VerifyHelper)
