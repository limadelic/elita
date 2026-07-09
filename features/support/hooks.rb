require 'timeout'

Around do |scenario, block|
  timeout_secs = if ENV["TAPE"] == "rec"
    300
  elsif ENV["COVER"] == "1"
    600
  else
    70
  end
  Timeout.timeout(timeout_secs) { block.call }
rescue Timeout::Error
  raise "Scenario '#{scenario.name}' timed out after #{timeout_secs}s"
end

Before do |scenario|
  tape_tag = scenario.tags.map(&:name).find { |t| t.start_with?("@tape:") }

  if tape_tag
    @cassette = tape_tag.sub("@tape:", "")
  else
    # Try to read cassette from Scenario Outline example row data
    test_case = scenario.instance_variable_get(:@test_case)
    if test_case && test_case.respond_to?(:rows)
      rows = test_case.rows
      if rows && !rows.empty?
        # For Scenario Outline, rows contains the example row data
        row_hash = rows.first.to_h if rows.first.respond_to?(:to_h)
        @cassette = row_hash['cassette'] if row_hash && row_hash['cassette']
      end
    end
  end

  @cassette ||= File.basename(scenario.location.file, ".feature")
  initialize_scenario_cursor
end

After do
  if @pid
    begin
      Process.kill("TERM", @pid)
      Process.wait(@pid, Process::WNOHANG)
    rescue Errno::ESRCH
    end
  end
  @reader.close if @reader && !@reader.closed?
  @writer.close if @writer && !@writer.closed?
end
