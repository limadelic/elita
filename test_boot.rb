require_relative 'features/support/hooks'
require_relative 'features/support/repl_helper'
require_relative 'features/support/spawn'
require_relative 'features/support/session_logs'

include ReplHelper
include Spawn
include SessionLogs

@cassette = "greet"
boot("malko")
sleep 1
puts "\n=== TRANSCRIPT ===\n#{@transcript}\n=== END ===\n"
puts "Shell PID: #{@pid}"

# Now look for malko_*.log files created after the boot
Dir.glob(File.expand_path("~/.elita/sessions/malko_*.log")).sort_by { |f| File.mtime(f) }.last(3).each do |f|
  puts "Found: #{File.basename(f)}"
  content = File.read(f)
  puts "  First line: #{content.lines.first.strip}"
end
