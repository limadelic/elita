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
  boot(args)
  drain
  handle(rest.first, transcript)
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  note(prompt, input) if table && valid?(table)
  write_input(input, prompt)
  output = retrying(15) { await_result(prompt, input) }
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
  @transcript_stripped ||= ''
  @transcript_stripped << "\n🤔 el → #{prompt}: #{input}\n"
end

def retrying(times, &block)
  attempt_with_retries(times, &block)
end

def verify_lines(lines)
  iterate_and_verify_lines(transcript.downcase, lines)
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
  idx = transcript.index(line.downcase, cursor)
  return idx + line.length if idx

  msg = "Expected '#{line}' in transcript after #{cursor}:\n#{transcript}"
  raise msg
end
