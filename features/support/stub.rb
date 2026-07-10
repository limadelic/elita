module Stub
  def write_stub_claude
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)

    splash = cassette_screen || fixture_splash

    claude_stub = File.join(bin_dir, 'claude')
    File.write(claude_stub, stub_script(splash))
    File.chmod(0755, claude_stub)

    # Write puppet stub (for malko or other names)
    puppet_stub = File.join(bin_dir, 'puppet_stub.rb')
    File.write(puppet_stub, stub_script(splash))
    File.chmod(0755, puppet_stub)

    el_escript = File.expand_path('../../apps/el/el', __dir__)
    el_wrapper = File.join(bin_dir, 'el')
    File.write(el_wrapper, el_wrapper_script(el_escript, puppet_stub))
    File.chmod(0755, el_wrapper)
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
      while line = STDIN.gets
        case line.strip
        when "/exit"
          break
        when "1+1"
          puts "2"
        end
        print prompt
        STDOUT.flush
      end
    SCRIPT
  end

  def el_wrapper_script(el_escript, puppet_stub_path)
    <<~SCRIPT
      #!/bin/bash

      # Check if first arg is a puppet name (malko)
      if [ "$1" = "malko" ]; then
        # Run stub as puppet
        export PUPPET_NAME="$1"
        exec ruby #{puppet_stub_path}
      else
        # Run real el
        exec #{el_escript} "$@"
      fi
    SCRIPT
  end
end

World(Stub)
