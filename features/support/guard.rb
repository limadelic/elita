require 'fileutils'

module Guard
  def enforce
    spurn
    handle
  end

  def handle
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

  STUB_SCRIPT = %{#!/bin/bash
# Stub claude for replay mode
cassette="$CASSETTE"
cassette_dir="$CASSETTE_DIR"
agent="$PUPPET_NAME"

[ -z "$cassette" ] && exit 1
[ -z "$cassette_dir" ] && exit 1
[ -z "$agent" ] && exit 1

cassette_file="$cassette_dir/$cassette.json"
[ ! -f "$cassette_file" ] && exit 1

screen=$(jq -r ".screens[\\"$agent\\"] // \\"\\"" "$cassette_file" 2>/dev/null)
[ -n "$screen" ] && echo "$screen"

while IFS= read -r line; do
  [ "$line" = "/exit" ] && break
done
}.freeze

  def stub_script
    STUB_SCRIPT
  end
end
