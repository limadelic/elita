require "pty"
require "expect"

When(/^> el\s*([^:]+)?$/) do |args|
  boot_el((args || "").strip)
end

When(/^(\w+)> ([^:]+):$/) do |expected_prompt, input, table|
  send_to_el(input, expected_prompt, table)
end

def boot_el(args)
  @el_pty = nil
  @el_reader = nil
  @el_pid = nil

  # Extract cassette name from feature tag or use default
  cassette_name = extract_cassette_name(args) || "greet"

  env = {
    "TAPE" => "replay",
    "CASSETTE" => cassette_name,
    "MIX_ENV" => "test"
  }

  el_bin = File.expand_path("./apps/el/el", Dir.pwd)
  cmd = "#{el_bin} #{args}".strip

  # Save environment and set test vars
  old_env = ENV.to_h
  begin
    env.each { |k, v| ENV[k] = v }

    # Use PTY.spawn which properly sets up the PTY connection
    # PTY.spawn returns reader, writer, pid
    @el_reader, @el_pty, @el_pid = PTY.spawn(cmd)
  ensure
    ENV.replace(old_env)
  end

  # Wait for prompt to appear (e.g., "greet>"), with detailed error reporting
  output = ""
  timeout = Time.now + 5
  prompt_pattern = /^#{Regexp.escape(args.split.first)}>/.freeze rescue />/

  begin
    while Time.now < timeout
      ready = IO.select([@el_reader], nil, nil, 0.1)
      if ready
        chunk = @el_reader.readpartial(4096)
        output << chunk

        # Check for the prompt
        if output.include?("#{args.split.first || 'greet'}>")
          @last_output = output
          return
        end
      end
    end
  rescue EOFError
    # Process ended before prompt appeared
  end

  # If we get here, prompt never appeared
  Process.kill("TERM", @el_pid) if @el_pid
  @el_pty.close if @el_pty

  raise "Boot failed: expected prompt after 'el #{args}' but got:\n#{output}\n\n" +
        "This likely means 'el #{args}' REPL mode is not implemented yet."
end

def extract_cassette_name(args)
  # Extract first argument as cassette name (e.g., "greet" from "el greet")
  first_arg = args.split.first
  first_arg unless first_arg.nil? || first_arg.empty?
end

def send_to_el(input, expected_prompt, table)
  raise "PTY not initialized - run '> el' first" unless @el_pty

  # Send input
  @el_pty.write("#{input}\n")
  @el_pty.flush

  # Read output until we see the prompt or timeout
  output = ""
  timeout = Time.now + 5

  begin
    while Time.now < timeout
      ready = IO.select([@el_reader], nil, nil, 0.1)
      if ready
        chunk = @el_reader.readpartial(4096)
        output << chunk

        # Check if we've received the prompt
        if output.include?("#{expected_prompt}>")
          break
        end
      end
    end
  rescue EOFError
    # Process ended
  end

  # Clean up the prompt from output
  lines_to_check = output.split("\n").reject { |line| line.include?("#{expected_prompt}>") }

  # Verify table cells appear in output (case-insensitive)
  table.raw.flatten.each do |cell|
    cell = cell.strip
    next if cell.empty?

    found = lines_to_check.any? { |line| line.downcase.include?(cell.downcase) }
    raise "Expected '#{cell}' in output:\n#{output}" unless found
  end

  @last_output = output
end
