module ReplHelper
  def boot(args)
    @cassette = @cassette || "greet"
    env = {
      "TAPE" => "replay",
      "CASSETTE" => @cassette,
      "MIX_ENV" => "test"
    }
    cmd = "./apps/el/el #{args}".strip
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait_for_prompt(args.split.first || "greet")
  end

  def send(input, prompt)
    raise "PTY not initialized" unless @writer
    @writer.write("#{input}\n")
    @writer.flush
    wait_for_prompt(prompt)
  end

  private

  def wait_for_prompt(prompt_word)
    output = ""
    timeout = Time.now + 5
    pattern = "#{prompt_word}>"

    begin
      while Time.now < timeout
        ready = IO.select([@reader], nil, nil, 0.1)
        if ready
          chunk = @reader.readpartial(4096)
          output << chunk
          return output if output.include?(pattern)
        end
      end
    rescue EOFError
    end

    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

World(ReplHelper)
