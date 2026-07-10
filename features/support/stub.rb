module Stub
  def write_stub_claude
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)

    splash_path = File.expand_path('fixtures/splash.txt', __dir__)
    splash = File.read(splash_path)

    claude_stub = File.join(bin_dir, 'claude')
    File.write(claude_stub, stub_script(splash))
    File.chmod(0755, claude_stub)

    el_escript = File.expand_path('../../apps/el/el', __dir__)
    el_link = File.join(bin_dir, 'el')
    File.symlink(el_escript, el_link) unless File.exist?(el_link)
  end

  private

  def stub_script(splash)
    <<~SCRIPT
      #!/usr/bin/env ruby

      # Print splash
      print #{splash.inspect}
      STDOUT.flush

      # Read stdin until /exit or EOF
      while line = STDIN.gets
        break if line.strip == '/exit'
      end
    SCRIPT
  end
end

World(Stub)
