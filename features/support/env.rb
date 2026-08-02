require "rspec/expectations"

ENV.delete("ANTHROPIC_API_KEY")
ENV["ELITA_RUN"] = Process.pid.to_s

module Env
end
