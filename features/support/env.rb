require "rspec/expectations"

BeforeAll do
  el_bin = File.expand_path("./apps/el/el", Dir.pwd)
  cassettes_dir = File.expand_path("./apps/elita/test/cassettes", Dir.pwd)

  puts "=== Building el binary ==="
  unless system("cd apps/el && mix escript.build 2>&1 > /dev/null")
    abort("Failed to build el binary")
  end

  puts "=== Verifying el binary exists ==="
  abort("#{el_bin} not found") unless File.exist?(el_bin)

  puts "=== Verifying cassettes directory ==="
  abort("#{cassettes_dir} not found") unless File.directory?(cassettes_dir)

  puts "=== Setup complete ==="
end

After do
  if @el_pid
    begin
      Process.kill("TERM", @el_pid)
      Process.wait(@el_pid, Process::WNOHANG)
    rescue Errno::ESRCH
      # Process already exited
    rescue
      # Ignore other errors
    end
  end

  if @el_pty
    begin
      @el_pty.close if !@el_pty.closed?
    rescue
      # Already closed
    end
  end
end
