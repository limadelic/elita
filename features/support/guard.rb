require 'fileutils'

module Guard
  def enforce
    spurn
    record? ? reject : stub
  end

  def record?
    ENV["TAPE"] == "rec"
  end

  def spurn
    bin_dir = File.join(@scratch, 'bin')
    stub_path = File.join(bin_dir, 'claude')
    raise "Fake claude stub detected at #{stub_path}" if File.exist?(stub_path)
  end

  def reject
    expected = '/opt/homebrew/bin/claude'
    actual = `which claude 2>/dev/null`.strip
    raise "Claude not found at #{expected}, found: #{actual}" unless actual == expected
  end

  def stub
    bin_dir = File.join(@scratch, 'bin')
    FileUtils.mkdir_p(bin_dir)
    stub_path = File.join(bin_dir, 'claude')
    script = stub_script
    File.write(stub_path, script)
    File.chmod(0755, stub_path)
  end

  def stub_script
    %q{#!/usr/bin/env ruby
require 'json'

def find_answer(tape, agent, query)
  tape.each do |entry|
    q = entry['q']
    next unless q['agent'] == agent

    messages = q.fetch('messages', [])
    messages.each do |msg|
      if msg['content'].strip == query
        a = entry.fetch('a', [])
        return a.first['text'] if a.first
      end
    end
  end
  nil
end

cassette = ENV['CASSETTE']
cassette_dir = ENV['CASSETTE_DIR']
agent = ENV['PUPPET_NAME']

exit 1 if cassette.nil? || cassette_dir.nil? || agent.nil?

cassette_file = File.join(cassette_dir, cassette + '.json')
exit 1 unless File.exist?(cassette_file)

data = JSON.parse(File.read(cassette_file))
screens = data['screens']
screen = screens[agent] if screens.is_a?(Hash)
puts screen if screen

tape = data.fetch('tape', [])

while line = $stdin.gets
  line.strip!
  break if line == '/exit'

  puts line
  answer = find_answer(tape, agent, line)
  puts answer if answer
  puts agent + '>'
end
    }.freeze
  end
end
