module ReplHelper
  def boot(args)
    @cassette = @cassette || "greet"
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "MIX_ENV" => "test"
    }
    cmd = "cd apps/elita/agents/elita && ../../../../apps/el/el #{args}".strip
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait_for_prompt(args.split.first || "el")
  end

  def one_shot(args)
    @cassette = @cassette || "greet"
    tape = ENV["TAPE"] || "replay"
    full_cmd = "cd apps/elita/agents/elita && TAPE=#{tape} CASSETTE=#{@cassette} MIX_ENV=test ../../../../apps/el/el #{args}"
    output = ""
    timeout = Time.now + 30

    begin
      reader, writer, pid = PTY.spawn("/bin/sh", "-c", full_cmd)
      while Time.now < timeout
        ready = IO.select([reader], nil, nil, 0.1)
        if ready
          chunk = reader.readpartial(4096)
          output << chunk
        end
      end
    rescue EOFError
    ensure
      Process.wait(pid) if pid
      writer.close if writer && !writer.closed?
    end

    output
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
    timeout = Time.now + 30
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
