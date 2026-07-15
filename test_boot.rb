require_relative 'features/support/hooks'
require_relative 'features/support/repl_helper'
require_relative 'features/support/spawn'
require_relative 'features/support/session_logs'

class TestBoot
  include ReplHelper
  include Spawn
  include SessionLogs

  def run
    @cassette = "greet"
    boot("malko")
    sleep 1
    report
  end

  def report
    puts "\n=== TRANSCRIPT ===\n#{@transcript}\n=== END ===\n"
    puts "Shell PID: #{@pid}"
    show_logs
  end

  def show_logs
    logs = Dir.glob(File.expand_path("~/.elita/sessions/malko_*.log"))
    logs.sort_by { |f| File.mtime(f) }.last(3).each do |f|
      puts "Found: #{File.basename(f)}"
      puts "  First line: #{File.read(f).lines.first.strip}"
    end
  end
end

TestBoot.new.run
