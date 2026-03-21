defmodule FileTest do
  use ExUnit.Case

  setup do
    n = "f#{:rand.uniform(999_999_999)}"
    md = "---\nname: #{n}\n---\n\nephemeral body"

    on_exit(fn ->
      :ets.delete(:elita_agents, {:agent, n})
    end)

    :ets.insert(:elita_agents, {{:agent, n}, md})
    %{name: n, md: md}
  end

  test "ephemeral hits namespaced ETS before disk", %{name: n, md: md} do
    assert Utils.File.file("#{n}.md") == md
  end
end
