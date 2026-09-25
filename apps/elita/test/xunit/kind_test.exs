defmodule KindTest do
  use ExUnit.Case
  @moduletag :xunit

  test "dispatch to a module-based kind" do
    name = "kind"
    {:ok, pid} = Elita.spawn(name, ["greet"], kind: TestKind)
    result = Agent.Harness.dispatch(name, "hello", :ask)
    assert result =~ "asked"
    Agent.Harness.dispatch(name, "world", :tell)

    on_exit(fn -> GenServer.stop(pid) end)
  end
end

defmodule TestKind do
  @behaviour Agent.Kind

  @impl true
  def ask(_entry, _recipient, message) do
    send(self(), {:kind_ask, message})
    "asked"
  end

  @impl true
  def forward(_entry, _recipient, message) do
    send(self(), {:kind_tell, message})
  end
end
