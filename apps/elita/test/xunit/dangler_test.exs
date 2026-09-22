defmodule DanglerTest do
  use ExUnit.Case
  @moduletag :xunit

  test "persona with empty frontmatter values still loads and composes" do
    config = Cfg.config("dangler")
    composed = Compose.compose([config])

    assert is_list(composed[:tools])
    assert composed[:tools] == []
  end

  test "persona with empty includes composes without crash" do
    config = Cfg.config("dangler")
    composed = Compose.compose([config])

    assert is_map(composed)
    assert composed[:name] == "dangler"
  end
end
