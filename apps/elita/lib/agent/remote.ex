defmodule Agent.Remote do
  import Enum, only: [find_value: 3]
  import String, only: [to_atom: 1, downcase: 1]

  def find(agent) do
    case :net_adm.names(~c"127.0.0.1") do
      {:ok, list} -> find_value(list, :undefined, &pick(&1, agent))
      _ -> :undefined
    end
  rescue
    _ -> :undefined
  end

  defp pick({name, _}, agent) do
    node = :erlang.list_to_binary(name)
    len = min(byte_size(agent) + 1, byte_size(node))
    case binary_part(node, 0, len) == <<agent::binary, "-">> do
      true -> call(node, agent)
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp call(node, agent) do
    norm = to_atom(agent) |> Kernel.to_string() |> downcase() |> to_atom()
    :erpc.call(to_atom("#{node}@127.0.0.1"), :global, :whereis_name, [{norm, :puppet}])
  rescue
    _ -> nil
  end
end
