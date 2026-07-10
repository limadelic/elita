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

When(/^> el (\w+)$/) do |agent, *rest|
  boot(agent)
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

Then(/^session closed$/) do
  raise "Session still alive" unless closed?
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
  yield
rescue => e
  (times -= 1).zero? ? (raise e) : (sleep 1 if ENV["TAPE"] == "rec"; retry)
end
