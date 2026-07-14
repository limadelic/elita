# frozen_string_literal: true

require 'pty'

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
  if args.start_with?("@")
    output = one(args)
    track(output, output.gsub(/\e\[[0-9;]*m/, ''))
  else
    boot(args)
    drain
  end
  handle(rest.first, transcript)
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  note(prompt, input) if table && valid?(table)
  write_input(input, prompt)
  output = retrying(15) { await_result(prompt, input) }
  reply(prompt, table, output) if table && valid?(table)
  settle(table, output)
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

  retrying(15) do
    verify_lines(table.raw.map { |row| row[0].strip })
  end
end

def handle(table, output)
  return unless table

  valid?(table) ? verify(table.raw) : table(table, output)
end

def settle(table, output)
  return unless table

  valid?(table) ? retrying(5) { verify(table.raw) } : retrying(5) { table(table, output) }
end

def track(chunk, stripped)
  @transcript ||= ''
  @transcript_stripped ||= ''
  @transcript << chunk
  @transcript_stripped << stripped
end

def note(prompt, input)
  # Do NOT fabricate emoji lines - they come from real Elixir output
end

def reply(prompt, table, output)
  # Do NOT fabricate emoji lines - they come from real Elixir output via session log
end

def valid_response_row?(table)
  return false unless table&.raw&.size.to_i > 1

  table.raw[1]&.size == 2
end

def log_response(prompt, text, _output)
  # Do NOT fabricate emoji lines - they come from real Elixir output via session log
end

def retrying(times, &block)
  attempt_with_retries(times, &block)
end

def verify_lines(lines)
  session_log = @current ? read_session_log(@current, @pid) : ""
  raise "No session log for #{@current}_#{@pid}" if session_log.empty?
  iterate_and_verify_lines(session_log.downcase, lines)
end

def attempt_with_retries(times, &block)
  block.call
rescue StandardError => e
  raise e if (times -= 1).zero?

  sleep pause_time
  attempt_with_retries(times, &block)
end

def iterate_and_verify_lines(transcript, lines)
  cursor = 0
  lines.each { |line| cursor = verify_line(line, transcript, cursor) }
end

def pause_time
  ENV['TAPE'] == 'rec' ? 1 : 0.5
end

def verify_line(line, transcript, cursor)
  transcript_str = transcript.force_encoding('UTF-8').downcase
  line_lower = line.downcase
  idx = transcript_str.index(line_lower, cursor)
  return idx + line.length if idx

  msg = "Expected '#{line}' in transcript after #{cursor}:\n#{transcript}"
  raise msg
end
