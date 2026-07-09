require "rspec/expectations"

BeforeAll do
  system("cd apps/el && mix escript.build 2>&1 > /dev/null") or abort("mix escript.build failed")
end
