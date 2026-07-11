module Stub
  def write_stub_claude
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)

    splash = cassette_screen || fixture_splash

    claude_stub = File.join(bin_dir, 'claude')
    File.write(claude_stub, stub_script(splash))
    File.chmod(0755, claude_stub)

    el_escript = File.expand_path('../../apps/el/el', __dir__)
    el_link = File.join(bin_dir, 'el')
    File.symlink(el_escript, el_link) unless File.exist?(el_link)
  end

  private

  def cassette_screen
    cassette_path = File.join(
      File.expand_path('../cassettes', __dir__),
      "#{@cassette}.json"
    )
    return nil unless File.exist?(cassette_path)

    begin
      data = JSON.parse(File.read(cassette_path))
      entry = data.find { |e| e.is_a?(Hash) && e.key?('screen') }
      entry&.fetch('screen', nil)
    rescue => e
      nil
    end
  end

  def fixture_splash
    splash_path = File.expand_path('fixtures/splash.txt', __dir__)
    File.read(splash_path)
  end

  def stub_script(splash)
    <<~SCRIPT
      #!/usr/bin/env ruby

      puppet_name = ENV["PUPPET_NAME"] || "malko"
      prompt = "\#{puppet_name}> "

      # Print splash
      print #{splash.inspect}
      print prompt
      STDOUT.flush

      # Read stdin and respond
      while line = STDIN.gets("\r")
        input = line.strip
        puts "🤔 \#{input}"
        answer = case input
                 when "/exit"
                   break
                 when "1+1"
                   "2"
                 when /^knock knock$/, /^malkovich knock knock$/
                   "Who's there?"
                 when /^malko$/, /^malkovich malko$/
                   "malko who?"
                 when /^malkovich$/
                   "Ha! Well played. That's a whole other branch, man."
                 when /^malkovich malkovich$/
                   "MALKOVICH! MALKOVICH!"
                 else
                   nil
                 end
        puts "⏺ \#{answer}" if answer
        print prompt
        STDOUT.flush
      end
    SCRIPT
  end

end

World(Stub)
