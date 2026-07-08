module ReplHelper
  def boot(args)
    @cassette = @cassette || "greet"
    @transcript = ""
    @transcript_stripped = ""
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "MIX_ENV" => "test"
    }
    cmd = spawn_cmd(args)
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait_for_prompt(args.split.first || "el")
  end

  def one_shot(args)
    @cassette = @cassette || "greet"
    tape = ENV["TAPE"] || "replay"
    escript_path = "../../../../apps/el/el"
    base_cmd = "cd apps/elita/agents/elita && TAPE=#{tape} CASSETTE=#{@cassette} MIX_ENV=test #{escript_path} #{args}"
    full_cmd = ENV["COVER"] == "1" ? cover_cmd(args, tape) : base_cmd
    output = ""
    duration = ENV["COVER"] == "1" ? 180 : 30
    timeout = Time.now + duration

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

  def transcript
    @transcript_stripped || ""
  end

  private

  def spawn_cmd(args)
    escript_path = "../../../../apps/el/el"
    base_cmd = "cd apps/elita/agents/elita && #{escript_path} #{args}"

    if ENV["COVER"] == "1"
      "cd /Users/mike/dev/self/elita-qa && mix cover -- #{args}"
    else
      base_cmd
    end.strip
  end

  def cover_cmd(args, tape)
    "cd /Users/mike/dev/self/elita-qa && TAPE=#{tape} CASSETTE=#{@cassette} MIX_ENV=test mix cover -- #{args}"
  end

  def strip_ansi(text)
    text.gsub(/\e\[[0-9;]*m/, "")
  end

  def wait_for_prompt(prompt_word)
    output = ""
    duration = if ENV["COVER"] == "1"
      180
    elsif ENV["TAPE"] == "rec"
      300
    else
      30
    end
    timeout = Time.now + duration
    pattern = "#{prompt_word}>"

    begin
      while Time.now < timeout
        ready = IO.select([@reader], nil, nil, 0.1)
        if ready
          chunk = @reader.readpartial(4096)
          output << chunk
          @transcript << chunk if @transcript
          stripped_chunk = strip_ansi(chunk)
          @transcript_stripped << stripped_chunk if @transcript_stripped
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
