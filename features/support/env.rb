require "rspec/expectations"

module Env
end

BeforeAll do
  cmd = "cd apps/el && mix escript.build 2>&1 > /dev/null"
  system(cmd) or abort("mix escript.build failed")
end
