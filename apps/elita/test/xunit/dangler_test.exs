defmodule DanglerTest do
  use ExUnit.Case
  @moduletag :xunit

  import Cfg, only: [config: 1]
  import Compose, only: [compose: 1]
  import Cfgs, only: [load: 1]

  test "persona with empty frontmatter values still loads and composes" do
    cfg = config("dangler")
    composed = compose([cfg])

    assert is_list(composed[:tools])
    assert composed[:tools] == []
  end

  test "persona with empty includes composes without crash" do
    configs = load(["dangler"])
    composed = compose(configs)

    assert is_map(composed)
    assert composed[:name] == "dangler"
  end
end
