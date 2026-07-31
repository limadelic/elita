defmodule Agent.Harness do
  @moduledoc "Routes ask/tell messages to agents based on registration kind."
  import Agent.Remote, only: [find: 1]
  import Registry, only: [lookup: 2]
  import String, only: [to_atom: 1]
  import :global, only: [whereis_name: 1]
  import Enum, only: [find_value: 3]
  import Node, only: [list: 0]
  import Utils.Normalize, only: [name: 1]

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

  defp global(n) do
    atom = to_atom(n)
    result = whereis_name({atom |> to_string() |> name(), :puppet})
    result |> local() |> remote(atom, result)
  end

  defp local(:undefined), do: :undefined
  defp local(found), do: found |> wrap()

  defp remote(:undefined, atom, _), do: list() |> search(atom)
  defp remote(found, _, _), do: found

  defp search(nodes, atom), do: find_value(nodes, :undefined, &fetch(&1, atom)) |> wrap()

  defp fetch(node, atom) do
    :erpc.call(node, :global, :whereis_name, [{atom |> to_string() |> name(), :puppet}], 5000)
  catch
    _, _ -> nil
  end

  defp fallback([], recipient), do: bare(recipient) |> find() |> wrap()
  defp fallback(found, _), do: found

  defp wrap(:undefined), do: []
  defp wrap(pid), do: [{pid, %{kind: :puppet}}]

  defp entry(recipient) do
    clean = bare(recipient)
    normalized = clean |> to_atom() |> Kernel.to_string() |> name()
    lookup(ElitaRegistry, normalized)
  end

  defp bare("el." <> n), do: n
  defp bare(n), do: n

  defp impl(:native), do: Agent.Kind.Native
  defp impl(:headless), do: Agent.Kind.Puppet
  defp impl(:puppet), do: Agent.Kind.Puppet

  defp ask!([{_pid, %{kind: kind}}] = entry, recipient, message) do
    impl(kind).ask(entry, recipient, message)
  end

  defp ask!([], recipient, _message), do: "unknown: #{recipient}"

  defp tell!([{_pid, %{kind: kind}}] = entry, recipient, message) do
    impl(kind).forward(entry, recipient, message)
  end

  defp tell!([], recipient, _message), do: "unknown: #{recipient}"
end
