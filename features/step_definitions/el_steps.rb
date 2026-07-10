require "pty"

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
  note(prompt, input) if table && valid?(table)
  output = retrying(5) { send(input, prompt) }
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
  retrying(5) {
    verify_lines(table.raw.map { |row| row[0].strip })
  }
end

private

def handle(table, output)
  return unless table

  valid?(table) ? verify(table.raw) : table(table, output)
end

def settle(table, output)
  return unless table

  valid?(table) ? retrying(5) { verify(table.raw) } : retrying(5) {
    table(table, output)
  }
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
  (times -= 1).zero? ? (raise first_error) : (sleep 1 if ENV["TAPE"] == "rec"; retry)
end

def verify_lines(lines)
  tx = transcript
  cursor = 0
  lines.each do |line|
    idx = tx.index(line, cursor)
    unless idx
      raise "Expected '#{line}' in transcript after position #{cursor}:\n#{tx}"
    end
    cursor = idx + line.length
  end
end
