module Guard
  def guard_live_claude
    bin_dir = File.join(@scratch, 'bin')
    stub_path = File.join(bin_dir, 'claude')
    raise "Fake claude stub detected at #{stub_path}" if File.exist?(stub_path)

    expected = '/opt/homebrew/bin/claude'
    actual = `which claude 2>/dev/null`.strip
    raise "Claude not found at #{expected}, found: #{actual}" unless actual == expected
  end
end
