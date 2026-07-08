require "pty"

When(/^> el(?!\s+tell\s)(\s[^:]+)?$/) do |args, *rest|
  table = rest.first
  boot((args || "").strip)
  if table && is_verify_table?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^> el (tell .+)$/) do |args, *rest|
  table = rest.first
  one_shot(args)
  if table && is_verify_table?(table)
    verify_lines(table.raw)
  elsif table
    verify_table(table, transcript)
  end
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first
  max_attempts = 5
  max_attempts.times do |attempt|
    begin
      output = send(input, prompt)
      if table && is_verify_table?(table)
        verify_lines(table.raw)
      elsif table
        verify_table(table, output)
      end
      break  # Success
    rescue => e
      if attempt < max_attempts - 1
        sleep 1 if ENV["TAPE"] == "rec"  # Backoff only during live recording
      else
        raise e  # Final attempt failed
      end
    end
  end
end

Then(/^verify$/) do |table|
  verify_lines(table.raw)
end
