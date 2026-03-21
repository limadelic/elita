defmodule DefineTest do
  use ExUnit.Case

  setup do
    n = "d#{:rand.uniform(999_999_999)}"

    on_exit(fn ->
      :ets.delete(:elita_agents, {:agent, n})
      :ets.delete(:elita_agents, n)
    end)

    %{name: n}
  end

  test "stores markdown under namespaced key", %{name: n} do
    {msg, state} =
      Tools.Sys.Define.exec("define", %{"name" => n, "prompt" => "be helpful"}, %{})

    assert msg =~ "defined"
    assert [{_, body}] = :ets.lookup(:elita_agents, {:agent, n})
    assert body =~ "be helpful"
    assert %{defined: [^n]} = state
  end
end
