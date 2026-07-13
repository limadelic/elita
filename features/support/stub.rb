module Stub
  def write_stub_claude
    bin_dir = ensure_bin_dir
    splash = cassette_screen || fixture_splash
    answers = cassette_answers
    write_claude_stub(bin_dir, splash, answers)
    link_el_escript(bin_dir)
  end

  def ensure_bin_dir
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
    bin_dir
  end

  def write_claude_stub(bin_dir, splash, answers)
    claude_stub = File.join(bin_dir, 'claude')
    File.write(claude_stub, stub_script(splash, answers))
    File.chmod(0755, claude_stub)
  end

  def link_el_escript(bin_dir)
    el_escript = File.expand_path('../../apps/el/el', __dir__)
    el_link = File.join(bin_dir, 'el')
    File.symlink(el_escript, el_link) unless File.exist?(el_link)
  end

  private

  def cassette_screen
    data = load_cassette_data
    return nil unless data

    entry = data.find { |e| e.is_a?(Hash) && e.key?('screen') }
    entry&.fetch('screen', nil)
  end

  def cassette_answers
    data = load_cassette_data
    return {} unless data

    data.each_with_object({}) { |entry, map| extract_qa_answer(entry, map) }
  rescue
    {}
  end

  def extract_qa_answer(entry, map)
    q, a = extract_qa(entry)
    return if q.nil?

    input = extract_input(q)
    return if input.nil?

    answer = find_text_answer(a)
    map[input] = answer['text'] if answer
  end

  def extract_qa(entry)
    return nil unless valid_entry?(entry)

    q, a = entry['q'], entry['a']
    return nil unless valid_qa_types?(q, a)

    [q, a]
  end

  def valid_entry?(entry)
    entry.is_a?(Hash) && entry.key?('q') && entry.key?('a')
  end

  def valid_qa_types?(q, a)
    q.is_a?(Hash) && a.is_a?(Array)
  end

  def extract_input(q)
    messages = q.fetch('messages', [])
    return nil unless messages.is_a?(Array) && messages.any?

    messages.first.fetch('content', '')
  end

  def find_text_answer(answers)
    answers.find { |item| item.is_a?(Hash) && item['type'] == 'text' }
  end

  def load_cassette_data
    cassette_path = File.join(
      File.expand_path('../cassettes', __dir__),
      "#{@cassette}.json"
    )
    return nil unless File.exist?(cassette_path)

    JSON.parse(File.read(cassette_path))
  rescue
    nil
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

        lines = input.split("\n").map { |l| l.strip.gsub(/^\[from \w+\]\s+/, "") }
        break if lines.include?("/exit")
        answer = lines.map { |l| answers[l] }.compact.first

        puts "⏺ \#{answer}" if answer
        print prompt
        STDOUT.flush
      end
    SCRIPT
  end
end

World(Stub)
