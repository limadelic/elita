require 'timeout'
require 'webrick'
require 'json'
require 'thread'

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
  @cassette = tape_tag ? tape_tag.sub("@tape:", "") : File.basename(scenario.location.file, ".feature")
  @tape_on_miss = scenario.tags.map(&:name).find { |t| t.start_with?("@tape_on_miss:") }
  @tape_on_miss = @tape_on_miss ? @tape_on_miss.sub("@tape_on_miss:", "") : nil
  initialize_scenario_cursor
  start_stub_server if @tape_on_miss == "live"
end

def start_stub_server
  @stub_port = 19999
  @stub_server = WEBrick::HTTPServer.new(
    Port: @stub_port,
    AccessLog: [],
    Logger: WEBrick::Log.new("/dev/null")
  )

  @stub_server.mount_proc("/v1/messages") do |req, res|
    if req.request_method == "POST"
      res["Content-Type"] = "application/json"
      res.body = JSON.generate({
        content: [{ type: "text", text: "response from stubbed server" }]
      })
    end
  end

  @stub_thread = Thread.new { @stub_server.start }
  sleep 0.1
  ENV["ANTHROPIC_BASE_URL"] = "http://localhost:#{@stub_port}"
end

def stop_stub_server
  if @stub_server
    @stub_server.shutdown
    @stub_thread&.join(1)
    ENV.delete("ANTHROPIC_BASE_URL")
  end
end

After do
  stop_stub_server
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
