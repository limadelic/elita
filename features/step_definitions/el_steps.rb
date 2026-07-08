require "pty"

When(/^> el (tell .+)$/) do |args, *rest|
  table = rest.first
  one_shot(args)
  if table && is_verify_table?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^> el(?!\s+tell\s)(\s[^:]+)?$/) do |args, *rest|
  table = rest.first
  boot((args || "").strip)
  if table && is_verify_table?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first

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
  if table && is_verify_table?(table)
    verify_lines(table.raw)
  elsif table
    # Retry table verification for transient failures
    max_table_attempts = 5
    max_table_attempts.times do |attempt|
      begin
        verify_table(table, output)
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
  verify_lines(table.raw)
end

Then(/^print transcript$/) do
  puts "\n=== TRANSCRIPT ===\n#{transcript}\n=== END ===\n"
end
