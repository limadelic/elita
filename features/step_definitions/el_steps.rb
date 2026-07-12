require "pty"
require_relative "../support/session_logs"

When(/^> el tell (.+)$/) do |args, *rest|
  output = one("tell #{args}")
  track(output, output.gsub(/\e\[[0-9;]*m/, ""))
  handle(rest.first, output)
end

When(/^> el$/) do |*rest|
  boot("")
  handle(rest.first, transcript)
end

When(/^> el (.+)$/) do |args, *rest|
  boot(args)
  drain
  handle(rest.first, transcript)
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  is_malko_scenario = ['door', 'portal', 'malkovich', 'hamlet'].include?(@cassette)
  has_emoji_rows = is_malko_scenario && has_emoji_markers?(table)
  note(prompt, input) if table && valid?(table) && !has_emoji_rows
  write_input(input, prompt)
  output = retrying(15) { await_result(prompt, input) }
  settle(table, output, prompt, is_malko_scenario)
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
  retrying(15) {
    verify_lines(table.raw.map { |row| row[0].strip })
  }
end

private

def handle(table, output)
  return unless table

  valid?(table) ? verify(table.raw) : table(table, output)
end

def settle(table, output, prompt = nil, is_malko = false)
  return unless table

  if valid?(table)
    if is_malko && has_emoji_markers?(table)
      retrying(5) { verify_session_markers(table.raw, prompt) }
    else
      retrying(5) { verify(table.raw) }
    end
  else
    retrying(5) { table(table, output) }
  end
end

def track(chunk, stripped)
  @transcript ||= ""
  @transcript_stripped ||= ""
  @transcript << chunk
  @transcript_stripped << stripped
end

def note(prompt, input)
  @transcript_stripped ||= ""
  @transcript_stripped << "\n🤔 el → #{prompt}: #{input}\n"
end

def retrying(times)
  first_error = nil
  yield
rescue => e
  first_error ||= e
  if (times -= 1).zero?
    raise first_error
  else
    pause = ENV["TAPE"] == "rec" ? 1 : 0.5
    sleep pause
    retry
  end
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

def has_emoji_markers?(table)
  return false unless table && table.raw

  # Only match specific traffic emoji markers: 🤔 📢 ✨
  traffic_emojis = ['🤔', '📢', '✨']
  table.raw.any? do |row|
    prefix = row[0].strip
    traffic_emojis.any? { |emoji| prefix.start_with?(emoji) }
  end
end

def verify_session_markers(rows, prompt)
  return if rows.empty?

  name = prompt
  log_content = find_session_log(name)
  raise "Session log not found for #{name}" if log_content.empty?

  rows.each do |row|
    prefix = row[0].strip
    text = row[1].strip

    unless log_content.include?(prefix) && (text.empty? || log_content.downcase.include?(text.downcase))
      raise "Expected '#{prefix}' and '#{text}' in session log for #{name}:\n#{log_content}"
    end
  end
end

def find_session_log(name)
  session_dir = File.join(File.expand_path("~"), ".elita/sessions")
  return "" unless Dir.exist?(session_dir)

  pattern = File.join(session_dir, "#{name}_*.log")
  logs = Dir.glob(pattern).sort_by { |f| File.mtime(f) }

  return "" if logs.empty?

  File.read(logs.last)
end
