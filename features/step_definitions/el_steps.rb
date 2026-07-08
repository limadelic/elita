require "pty"

When(/^> el\s*([^:]+)?$/) do |args|
  boot((args || "").strip)
end

When(/^(\w+)> ([^:]+):$/) do |prompt, input, table|
  output = send(input, prompt)
  verify_table(table, output)
end
