module Stub
  def write_stub_claude
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)

    splash = cassette_screen || fixture_splash
    answers = cassette_answers

    claude_stub = File.join(bin_dir, 'claude')
    File.write(claude_stub, stub_script(splash, answers))
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

  def cassette_answers
    cassette_path = File.join(
      File.expand_path('../cassettes', __dir__),
      "#{@cassette}.json"
    )
    return {} unless File.exist?(cassette_path)

    begin
      data = JSON.parse(File.read(cassette_path))
      data.each_with_object({}) do |entry, map|
        next unless entry.is_a?(Hash) && entry.key?('q') && entry.key?('a')

        q = entry['q']
        a = entry['a']
        next unless q.is_a?(Hash) && a.is_a?(Array)

        messages = q.fetch('messages', [])
        next unless messages.is_a?(Array) && messages.any?

        input = messages.first.fetch('content', '')
        answer_text = a.find { |item| item.is_a?(Hash) && item['type'] == 'text' }
        map[input] = answer_text['text'] if answer_text
      end
    rescue => e
      {}
    end
  end

  def fixture_splash
    splash_path = File.expand_path('fixtures/splash.txt', __dir__)
    File.read(splash_path)
  end

  def stub_script(splash, answers)
    answers_hash = answers.inspect
    <<~SCRIPT
      #!/usr/bin/env ruby

      puppet_name = ENV["PUPPET_NAME"] || "malko"
      prompt = "\#{puppet_name}> "
      answers = #{answers_hash}

      # Print splash
      print #{splash.inspect}
      print prompt
      STDOUT.flush

      # Read stdin and respond
      while line = STDIN.gets("\r")
        input = line.strip
        puts "🤔 \#{input}"

        answer = if input == "/exit"
                   break
                 else
                   answers[input]
                 end

        puts "⏺ \#{answer}" if answer
        print prompt
        STDOUT.flush
      end
    SCRIPT
  end

end

World(Stub)
