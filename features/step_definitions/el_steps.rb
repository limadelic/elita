# frozen_string_literal: true

require 'pty'
require_relative '../support/session_logs'

When(/^> el tell (.+)$/) do |args, *rest|
  output = one("tell #{args}")
  track(output, output.gsub(/\e\[[0-9;]*m/, ''))
  handle(rest.first, output)
end

When(/^> el$/) do |*rest|
  boot('')
  handle(rest.first, transcript)
end

When(/^> el (.+)$/) do |args, *rest|
  boot(args)
  drain
  handle(rest.first, transcript)
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  is_malko_scenario = %w[door portal malkovich hamlet].include?(@cassette)
  has_emoji_rows = is_malko_scenario && emoji_markers?(table)
  note(prompt, input) if table && valid?(table) && !has_emoji_rows
  write_input(input, prompt)
  output = retrying(15) { await_result(prompt, input) }
  settle(table, output, prompt, is_malko: is_malko_scenario)
end

Then(/^verify$/) do |table|
  verify(table.raw)
end

Then(/^print transcript$/) do
  puts "\n=== TRANSCRIPT ===\n#{transcript}\n=== END ===\n"
end

Then(/^screen shows (.+)$/) do |text|
  unless screen.include?(text)
    raise "Screen does not contain '#{text}':\n#{screen}"
  end
end

When(/^(\w+):$/) do |name, *rest|
  table = rest.first
  activate(name)
  return unless table

  # Separate emoji marker rows from transcript lines
  emoji_rows = []
  transcript_rows = []
  table.raw.each do |row|
    if row.length == 2 && traffic_emoji?(row[0])
      emoji_rows << row
    else
      transcript_rows << row[0].strip
    end
  end

  # Verify transcript lines
  retry_count = ENV['AUTONOMY_PROBE'] ? 30 : 15
  if transcript_rows.any?
    retrying(retry_count) { verify_lines(transcript_rows) }
  end

  # Verify emoji markers in session log
  retrying(15) { verify_session_markers(emoji_rows, name) } if emoji_rows.any?
end

def traffic_emoji?(text)
  traffic_emojis = %w[🤔 📢 ✨]
  traffic_emojis.any? { |emoji| text.strip.start_with?(emoji) }
end

def handle(table, output)
  return unless table

  valid?(table) ? verify(table.raw) : table(table, output)
end

def settle(table, output, prompt = nil, is_malko: false)
  return unless table

  if valid?(table)
    if is_malko && emoji_markers?(table)
      retrying(15) { verify_session_markers(table.raw, prompt) }
    else
      retrying(5) { verify(table.raw) }
    end
  else
    retrying(5) { table(table, output) }
  end
end

def track(chunk, stripped)
  @transcript ||= ''
  @transcript_stripped ||= ''
  @transcript << chunk
  @transcript_stripped << stripped
end

def note(prompt, input)
  @transcript_stripped ||= ''
  @transcript_stripped << "\n🤔 el → #{prompt}: #{input}\n"
end

def retrying(times)
  first_error = nil
  yield
rescue StandardError => e
  first_error ||= e
  raise first_error if (times -= 1).zero?

  pause = ENV['TAPE'] == 'rec' ? 1 : 0.5
  sleep pause
  retry
end

def verify_lines(lines)
  tx = transcript.downcase
  cursor = 0
  lines.each do |line|
    idx = tx.index(line.downcase, cursor)
    unless idx
      raise "Expected '#{line}' in transcript after position #{cursor}:\n#{tx}"
    end

    cursor = idx + line.length
  end
end

def emoji_markers?(table)
  return false unless table&.raw

  # Only match specific traffic emoji markers: 🤔 📢 ✨
  traffic_emojis = %w[🤔 📢 ✨]
  table.raw.any? do |row|
    prefix = row[0].strip
    traffic_emojis.any? { |emoji| prefix.start_with?(emoji) }
  end
end

def verify_session_markers(rows, prompt)
  return if rows.empty?

  name = prompt
  search_text = rows.first[1].strip if rows.first && rows.first.length > 1
  log_content = find_session_log(name, search_text)
  raise "Session log not found for #{name}" if log_content.empty?

  rows.each { |row| check_marker_row(row, name, log_content) }
end

def check_marker_row(row, name, log_content)
  prefix = row[0].strip
  text = row[1].strip

  has_prefix = log_content.include?(prefix)
  has_text = text.empty? || log_content.downcase.include?(text.downcase)
  return if has_prefix && has_text

  raise "Expected '#{prefix}' and '#{text}' in #{name}:\n#{log_content}"
end

def find_session_log(name, search_text = nil)
  session_dir = session_directory
  return '' unless Dir.exist?(session_dir)

  logs = logs_for(session_dir, name)
  return '' if logs.empty?

  by_text = search_text_in_logs(logs, search_text)
  return by_text if by_text

  by_emoji = search_emoji_in_logs(logs)
  return by_emoji if by_emoji

  File.read(logs.last)
end

def session_directory
  File.join(File.expand_path('~'), '.elita/sessions')
end

def logs_for(session_dir, name)
  pattern = File.join(session_dir, "#{name}_*.log")
  Dir.glob(pattern).sort_by { |f| File.mtime(f) }
end

def search_text_in_logs(logs, search_text)
  return nil unless search_text

  search_lower = search_text.downcase
  logs.reverse.each do |log_path|
    content = File.read(log_path)
    return content if content.downcase.include?(search_lower)
  end
  nil
end

def search_emoji_in_logs(logs)
  traffic_emojis = %w[🤔 📢 ✨]
  logs.reverse.each do |log_path|
    content = File.read(log_path)
    return content if traffic_emojis.any? { |emoji| content.include?(emoji) }
  end
  nil
end
