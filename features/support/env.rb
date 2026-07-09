require "rspec/expectations"

BeforeAll do
  build!
end

private

def build!
  system("cd apps/el && mix escript.build 2>&1 > /dev/null") or
    abort("mix escript.build failed")
end
