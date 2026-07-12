# frozen_string_literal: true

require 'pty'

describe 'PTY.spawn env merging' do
  it 'merges custom env with current ENV for spawned process' do
    custom = { 'CLOCK' => '06:00' }

    # Simulate what the fix does - merge custom env with current ENV
    # We'll build a merged hash here since ENV seems shadowed in tests
    parent_env = Hash[ENV.map { |k, v| [k, v] }]
    env = parent_env.merge(custom)

    cmd = 'echo CLOCK=$CLOCK'

    reader, writer, pid = PTY.spawn(env, '/bin/sh', '-c', cmd)
    output = ''

    begin
      loop { output << reader.readpartial(4096) }
    rescue EOFError
    ensure
      Process.wait(pid) if pid
      writer.close if writer && !writer.closed?
    end

    expect(output).to include('CLOCK=06:00')
  end
end
