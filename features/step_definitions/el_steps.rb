require "pty"

When(/^> el(?!\s+tell\s)(\s[^:]+)?$/) do |args|
  boot((args || "").strip)
end

When(/^> el (tell .+)$/) do |args|
  one_shot(args)
end

When(/^(\w+)> ([^:]+):$/) do |prompt, input, table|
  max_attempts = 5
  max_attempts.times do |attempt|
    begin
      output = send(input, prompt)
      verify_table(table, output)
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

When(/^(\w+)> ([^:]+)$/) do |prompt, input|
  send(input, prompt)
end
