defmodule KindTest do
  use ExUnit.Case
  @moduletag :xunit

  test "dispatch to a module-based kind" do
    name = :tester
    opts = [kind: TestKind]
    {:ok, _pid} = Elita.spawn(to_string(name), ["tester"], opts)
    result = Agent.Harness.dispatch(to_string(name), "hello", :ask)
    assert result =~ "asked"
    Agent.Harness.dispatch(to_string(name), "world", :tell)

    on_exit(fn ->
      GenServer.stop(registry_lookup(to_string(name)))
    end)
  end

  defp registry_lookup(name) do
    normalized = name |> String.downcase()

    case Registry.lookup(ElitaRegistry, normalized) do
      [{pid, _meta}] -> pid
      _ -> nil
    end
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
