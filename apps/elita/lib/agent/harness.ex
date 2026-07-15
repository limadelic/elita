defmodule Agent.Harness do
  @moduledoc "Routes ask/tell messages to agents based on registration kind."
  import Agent.Session, only: [ask: 2, forward: 2]
  import Agent.Remote, only: [find: 1]
  import Elita, only: [request: 2, dispatch: 2]
  import Registry, only: [lookup: 2]
  import String, only: [to_atom: 1, downcase: 1]
  import :global, only: [whereis_name: 1]
  import Enum, only: [find_value: 3]
  import Node, only: [list: 0]

  def dispatch(recipient, message, :ask) do
    recipient |> locate() |> ask!(recipient, message)
  end

  def dispatch(recipient, message, :tell) do
    recipient |> locate() |> tell!(recipient, message)
  end

  defp locate(recipient) do
    entry(recipient) |> nearby(recipient)
  end

  defp nearby([], recipient), do: global(bare(recipient)) |> fallback(recipient)
  defp nearby(found, _recipient), do: found

  defp global(name) do
    atom = to_atom(name)
    result = whereis_name({atom, :puppet})
    result |> local() |> remote(atom, result)
  end

  defp local(:undefined), do: :undefined
  defp local(found), do: found |> wrap()

  defp remote(:undefined, atom, _), do: list() |> search(atom)
  defp remote(found, _, _), do: found

  defp search(nodes, atom), do: find_value(nodes, :undefined, &fetch(&1, atom)) |> wrap()

  defp fetch(node, atom) do
    :erpc.call(node, :global, :whereis_name, [{atom, :puppet}])
  rescue
    _ ->
      nil
  end

  defp fallback([], recipient), do: bare(recipient) |> find() |> wrap()
  defp fallback(found, _), do: found

  defp wrap(:undefined), do: []
  defp wrap(pid), do: [{pid, %{kind: :puppet}}]

  defp entry(recipient) do
    clean = bare(recipient)
    normalized = clean |> to_atom() |> Kernel.to_string() |> downcase()
    lookup(ElitaRegistry, normalized)
  end

  defp bare("el." <> name), do: name
  defp bare(name), do: name

  defp ask!([{_pid, %{kind: :native}}], recipient, message) do
    request(to_atom(recipient), message)
  end

  defp ask!([{pid, %{kind: kind}}], _recipient, message)
       when kind in [:headless, :puppet] do
    {:ok, response} = ask(pid, message)
    response
  end

  defp ask!([], recipient, _message), do: "unknown: #{recipient}"

  defp tell!([{_pid, %{kind: :native}}], recipient, message) do
    dispatch(to_atom(recipient), message)
  end

  defp tell!([{pid, %{kind: kind}}], _recipient, message)
       when kind in [:headless, :puppet] do
    forward(pid, message)
  end

  defp tell!([], recipient, _message), do: "unknown: #{recipient}"
end
