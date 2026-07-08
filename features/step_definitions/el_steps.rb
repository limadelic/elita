require "pty"

When(/^> el(?!\s+tell\s)(\s[^:]+)?$/) do |args|
  boot((args || "").strip)
end

When(/^> el (tell .+)$/) do |args|
  one_shot(args)
end

When(/^(\w+)> ([^:]+):$/) do |prompt, input, table|
  output = send(input, prompt)
  verify_table(table, output)
end

When(/^(\w+)> ([^:]+)$/) do |prompt, input|
  send(input, prompt)
end
