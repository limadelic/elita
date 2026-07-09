module ReplHelper
  def dir
    File.expand_path("../cassettes", __dir__)
  end

  def boot(args)
    @cassette = @cassette || "greet"
    @transcript = ""
    @transcript_stripped = ""
    env = {
      "TAPE" => ENV["TAPE"] || "replay",
      "CASSETTE" => @cassette,
      "CASSETTE_DIR" => dir,
      "MIX_ENV" => "test"
    }
    env["TAPE_ON_MISS"] = @tape_on_miss if @tape_on_miss
    cmd = spawn(args)
    @reader, @writer, @pid = PTY.spawn(env, "/bin/sh", "-c", cmd)
    wait(args.split.first || "el")
  end

  def one(args)
    @cassette = @cassette || "greet"
    tape = ENV["TAPE"] || "replay"
    escript_path = "../../../../apps/el/el"
    cmd = (
      "cd apps/elita/agents/elita && " +
      "TAPE=#{tape} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{escript_path} " +
      "#{args}"
    ).strip
    output = ""
    timeout = Time.now + 30

    begin
      reader, writer, pid = PTY.spawn("/bin/sh", "-c", cmd)
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
    wait(prompt)
  end

  def transcript
    @transcript_stripped || ""
  end

  def drain
    return unless @reader

    chunk = absorb(@reader)
    chunk = encode(chunk)
    @transcript << chunk if @transcript
    stripped_chunk = strip(chunk)
    stripped_chunk = encode(stripped_chunk)
    @transcript_stripped << stripped_chunk if @transcript_stripped
  end

  private

  def absorb(pty)
    output = ""
    begin
      while true
        ready = IO.select([pty], nil, nil, 0.1)
        if ready
          chunk = pty.readpartial(4096)
          output << chunk
        else
          break
        end
      end
    rescue EOFError
    end
    output
  end

  def fetch(pty)
    ready = IO.select([pty], nil, nil, 0.1)
    return "" unless ready

    chunk = pty.readpartial(4096)
    encode(chunk)
  rescue EOFError
    ""
  end

  def encode(value)
    value.force_encoding("UTF-8") rescue value.to_s
  end

  def spawn(args)
    escript_path = "../../../../apps/el/el"
    (
      "cd apps/elita/agents/elita && " +
      "TAPE=#{ENV['TAPE'] || 'replay'} " +
      "CASSETTE=#{@cassette} " +
      "CASSETTE_DIR=#{dir} " +
      "MIX_ENV=test " +
      "#{escript_path} " +
      "#{args}"
    ).strip
  end

  def strip(text)
    text.force_encoding("UTF-8").scrub("").gsub(/\e\[[0-9;]*m/, "")
  end

  def wait(prompt_word)
    output = ""
    duration = ENV["TAPE"] == "rec" ? 300 : 30
    timeout = Time.now + duration
    pattern = "#{prompt_word}>"

    begin
      while Time.now < timeout
        chunk = fetch(@reader)
        next if chunk.empty?

        output << chunk
        @transcript << chunk if @transcript
        stripped_chunk = strip(chunk)
        stripped_chunk = encode(stripped_chunk)
        @transcript_stripped << stripped_chunk if @transcript_stripped
        return output if output.include?(pattern)
      end
    rescue EOFError
    end

    Process.kill("TERM", @pid) if @pid
    @writer.close if @writer && !@writer.closed?
    raise "Timeout waiting for '#{pattern}' in:\n#{output}"
  end
end

World(ReplHelper)
