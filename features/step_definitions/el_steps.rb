# frozen_string_literal: true

require 'pty'

When(/^a folder outside the repo with bob.md$/) do
  @scratch = Dir.mktmpdir('bob')
  copy_el_binary
  write_bob_file
end

def copy_el_binary
  bin_dir = File.join(@scratch, 'bin')
  Dir.mkdir(bin_dir)
  el_escript = File.expand_path('../../apps/el/el', __dir__)
  FileUtils.cp(el_escript, File.join(bin_dir, 'el'))
  File.chmod(0755, File.join(bin_dir, 'el'))
end

def write_bob_file
  bob_file = File.join(@scratch, 'bob.md')
  File.write(bob_file, bob_content)
end

def bob_content
  prompt = "Answer in two lines. Line 1: bob here. Line 2: your answer.\n\nBob the agent."
  "---\nname: bob\ndescription: Agent Bob\n---\n\n# Bob\n\n#{prompt}"
end

When(/^no elita node$/) do
  @elita_run = "nosuch"
end

When(/^clock (.+)$/) do |time|
  @clock = time
end

When(/^cassette (.+)$/) do |name|
  @cassette = name
end

When(/^> el tell (.+)$/) do |args, *rest|
  output = one("tell #{args}")
  track(output, output.gsub(/\e\[[0-9;]*m/, ''))
  handle(rest.first, output)
end

When(/^> el spawn (.+)$/) do |args, *rest|
  output = one("spawn #{args}")
  track(output.dup, output.gsub(/\e\[[0-9;]*m/, ''))
  handle(rest.first, output)
end

When(/^> el$/) do |*rest|
  boot('')
  handle(rest.first, transcript)
end

When(/^> el (?!tell|spawn)(.+)$/) do |args, *rest|
  route(args)
  handle(rest.first, transcript)
end

When(/^(\w+)> (.+)$/) do |prompt, input, *rest|
  table = rest.first

  note(prompt, input) if table && valid?(table)
  emit(input, prompt)
  output = retrying(15) { collect(prompt, input) }
  reply(prompt, table, output) if table && valid?(table)
  settle(table, output)
end

Then(/^verify$/) do |table|
  verify(table.raw)
end

Then(/^print transcript$/) do
  puts "\n=== TRANSCRIPT ===\n#{transcript}\n=== END ===\n"
end

Then(/^screen shows (.+)$/) do |text|
  check(text)
end

Then(/^el fails$/) do
  raise "Exit status not captured" unless @exit_status

  exitstatus = @exit_status.exitstatus
  raise "expected nonzero, got #{exitstatus}" if exitstatus&.zero?
end

Then(/^(\w+) hears$/) { |name, table| freeq_hears(name, table) }

Then(/^(\w+) hears nothing more$/) do |name|
  freeq_quiet(name)
end

When(/^(\w+):$/) do |name, *rest|
  table = rest.first
  activate(name)
  return unless table

  retrying(15) do
    trace(table.raw.map { |row| row.map(&:strip).join(" | ") })
  end
end

def handle(table, output)
  return unless table

  respond(table, output)
end

def respond(table, output)
  valid?(table) ? verify(table.raw) : table(table, output)
end

def settle(table, output)
  return unless table

  finalize(table, output)
end

def finalize(table, output)
  valid?(table) ? retrying(5) { verify(table.raw) } : retrying(5) { table(table, output) }
end

def track(chunk, stripped)
  if @transcript.nil?
    @transcript = +""
    @transcript_stripped = +""
  end
  @transcript << chunk
  @transcript_stripped << stripped
end

def note(prompt, input)
end

def reply(prompt, table, output)
end

def sound?(table)
  sufficient?(table) && sized?(table)
end

def sufficient?(table)
  table.raw.size > 1
rescue StandardError
  false
end

def sized?(table)
  table.raw[1].size == 2
rescue StandardError
  false
end

def silence(prompt, text, _output)
end

def retrying(times, &block)
  effective_times = live? ? quota : times
  persist(effective_times, &block)
end

def live?
  ENV["LIVE"] == "1"
end

def quota
  (60.0 / pause).ceil
end

def trace(lines)
  log = source
  raise "No session log for #{@current}_#{@pid}" if log.empty?

  iterate(log.downcase, lines)
end

def source
  branch? ? recording : session
end

def branch?
  replay? && stub?
end

def recording
  @transcript_stripped || ""
end

def session
  @current ? pull(@current, @pid) : ""
end

def replay?
  ENV["TAPE"] != "rec"
end

def persist(times, &block)
  block.call
rescue StandardError => e
  decide(times, e, &block)
end

def decide(times, error, &block)
  return raise error if (times -= 1).zero?

  sleep pause
  persist(times, &block)
end

def iterate(transcript, lines)
  cursor = 0
  lines.each { |line| cursor = sight(line, transcript, cursor) }
end

def route(args)
  return execute(args) if at?(args)

  delegate(args)
end

def delegate(args)
  injectable?(args) ? inject(args) : start(args)
end

def injectable?(args)
  aimed?(args) && !alias?(args)
end

def at?(args)
  args.start_with?("@")
end

def alias?(args)
  args.include?(" as ")
end

def aimed?(args)
  args.include?(" ") && @current
end

def execute(args)
  output = one(args)
  track(output, output.gsub(/\e\[[0-9;]*m/, ''))
end

def inject(args)
  emit(args, @current)
  output = retrying(15) { collect(@current, args) }
  track(output, output.gsub(/\e\[[0-9;]*m/, ''))
end

def start(args)
  boot(args)
  drain
end

def check(text)
  raise "Screen does not contain '#{text}':\n#{screen}" unless screen.include?(text)
end

def pause
  ENV['TAPE'] == 'rec' ? 1 : 0.5
end

def sight(line, transcript, cursor)
  transcript_str = transcript.force_encoding('UTF-8').downcase
  line_lower = line.downcase
  idx = transcript_str.index(line_lower, cursor)
  return idx + line.length if idx

  msg = "Expected '#{line}' in transcript after #{cursor}:\n#{transcript}"
  raise msg
end
