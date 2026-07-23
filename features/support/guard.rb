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
    cassette_file = File.join(dir, "#{@cassette}.json")
    script = stub_script(cassette_file)
    File.write(stub_path, script)
    File.chmod(0755, stub_path)
  end

  def stub_script(cassette_file)
    path = cassette_file.inspect
    %Q{#!/usr/bin/env ruby
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

cassette_file = #{path}
agent = ENV['PUPPET_NAME'] || ARGV[-1]

unless agent
  puts "ERROR: agent name required (via PUPPET_NAME or last argument)"
  exit 1
end

unless File.exist?(cassette_file)
  puts "ERROR: cassette file not found: " + cassette_file
  exit 1
end

data = JSON.parse(File.read(cassette_file))
screens = data['screens']
screen = screens[agent] if screens.is_a?(Hash)

unless screen
  puts "ERROR: no screen data for agent: " + agent
  exit 1
end

puts screen

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
