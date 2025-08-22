defmodule SpecTest do
  use Tester, async: true

  # Automatically generate tests for all specs
  for spec <- Path.wildcard("test/specs/*_spec.md") do
    name = spec |> Path.basename(".md") |> String.replace("_spec", "")

    test "#{name} spec" do
      spawn(:sut, :tester)
      verify(:sut, "passed", "test #{unquote(name)}")
    end
  end
end
