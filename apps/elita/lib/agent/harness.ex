defmodule Agent.Harness do
  @moduledoc "Routes ask/tell messages to agents based on registration kind."

  import Agent.Session, only: [ask: 2, cast: 2]
  import Elita, only: [request: 2, dispatch: 2]
  import Registry, only: [lookup: 2]
  import String, only: [to_atom: 1, downcase: 1]

  def dispatch(recipient, message, :ask) do
    recipient
    |> entry()
    |> ask!(recipient, message)
  end

  def dispatch(recipient, message, :tell) do
    recipient
    |> entry()
    |> tell!(recipient, message)
  end

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

  defp ask!([{pid, %{kind: :headless}}], _recipient, message) do
    {:ok, response} = ask(pid, message)
    response
  end

  defp ask!([{pid, %{kind: :puppet}}], _recipient, message) do
    {:ok, response} = ask(pid, message)
    response
  end

  defp ask!([], recipient, _message) do
    "unknown: #{recipient}"
  end

  defp tell!([{_pid, %{kind: :native}}], recipient, message) do
    dispatch(to_atom(recipient), message)
  end

  defp tell!([{pid, %{kind: :headless}}], _recipient, message) do
    cast(pid, message)
  end

  defp tell!([{pid, %{kind: :puppet}}], _recipient, message) do
    cast(pid, message)
  end

  defp tell!([], recipient, _message) do
    "unknown: #{recipient}"
  end
end
