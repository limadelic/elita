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
    logs
  end

  def logs
    file_logs = Dir.glob(File.expand_path("~/.elita/sessions/malko_*.log"))
    recent = file_logs.sort_by { |f| File.mtime(f) }.last(3)
    glance(recent)
  end

  def glance(recent)
    recent.each do |f|
      puts "Found: #{File.basename(f)}"
      puts "  First line: #{File.read(f).lines.first.strip}"
    end
  end
end

TestBoot.new.run
