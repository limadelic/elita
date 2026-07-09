require "pty"

When(/^> el tell (.+)$/) do |args, *rest|
  table = rest.first
  output = one_shot("tell #{args}")

  # Accumulate output into transcript for verify_lines retry-drain
  @transcript ||= ""
  @transcript_stripped ||= ""
  @transcript << output
  stripped = output.gsub(/\e\[[0-9;]*m/, "")
  @transcript_stripped << stripped

  if table && valid?(table)
    verify(table.raw)
  elsif table
    table(table, output)
  end
end

When(/^> el$/) do |*rest|
  table = rest.first
  boot("")
  if table && valid?(table)
    verify(table.raw)
  elsif table
    table(table, transcript)
  end
end

When(/^> el (\w+)$/) do |agent, *rest|
  table = rest.first
  boot(agent)
  if table && valid?(table)
    drain_pty
    verify(table.raw)
  elsif table
    table(table, transcript)
  end
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first

  # Add request log to transcript for verify_lines tables
  # before sending so it's properly captured
  if table && valid?(table)
    @transcript_stripped ||= ""
    @transcript_stripped << "\n🤔 el → #{prompt}: #{input}\n"
  end

  # Retry the send() for network issues
  max_send_attempts = 5
  output = nil
  max_send_attempts.times do |attempt|
    begin
      output = send(input, prompt)
      break
    rescue => e
      if attempt < max_send_attempts - 1
        sleep 1 if ENV["TAPE"] == "rec"
      else
        raise e
      end
    end
  end

  # Check table if present
  if table && valid?(table)
    verify(table.raw)
  elsif table
    # Retry table verification for transient failures
    max_table_attempts = 5
    max_table_attempts.times do |attempt|
      begin
        table(table, output)
        break
      rescue => e
        if attempt < max_table_attempts - 1
          sleep 1 if ENV["TAPE"] == "rec"
        else
          raise e
        end
      end
    end
  end
end

Then(/^verify$/) do |table|
  verify(table.raw)
end

Then(/^speck generates scenarios$/) do |table|
  verify(table.raw)
end

Then(/^speck runs the test suite$/) do |table|
  verify(table.raw)
end

Then(/^print transcript$/) do
  puts "\n=== TRANSCRIPT ===\n#{transcript}\n=== END ===\n"
end
