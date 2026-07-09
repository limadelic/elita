require "pty"

When(/^> el tell (.+)$/) do |args, *rest|
  table = rest.first
  output = shot("tell #{args}")

  @transcript ||= ""
  @transcript_stripped ||= ""
  @transcript << output
  @transcript_stripped << output.gsub(/\e\[[0-9;]*m/, "")

  if table && valid?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, output)
  end
end

When(/^> el$/) do |*rest|
  table = rest.first
  boot("")
  if table && valid?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^> el (\w+)$/) do |agent, *rest|
  table = rest.first
  boot(agent)
  if table && valid?(table)
    drain
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  valid = table && valid?(table)

  if valid
    @transcript_stripped ||= ""
    @transcript_stripped << "\n🤔 el → #{prompt}: #{input}\n"
  end

  output = attempt(5) { send(input, prompt) }

  if valid
    verify_lines(table.raw)
  elsif table
    attempt(5) { verify_table(table, output) }
  end
end

Then(/^verify$/) do |table|
  verify_lines(table.raw)
end

Then(/^print transcript$/) do
  puts "\n=== TRANSCRIPT ===\n#{transcript}\n=== END ===\n"
end

def attempt(max_tries = 5)
  result = nil
  max_tries.times do |try|
    begin
      result = yield
      break
    rescue => e
      raise if try >= max_tries - 1
      sleep 1 if ENV["TAPE"] == "rec"
    end
  end
  result
end
