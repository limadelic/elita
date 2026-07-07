defmodule Agent.Harness do
  @moduledoc "Routes ask/tell messages to agents based on registration kind."

  import Agent.Session, only: [ask: 2, cast: 2]
  import String, only: [to_atom: 1, downcase: 1]

  def dispatch(recipient, message, :ask) do
    recipient
    |> lookup
    |> handle_ask(recipient, message)
  end

  def dispatch(recipient, message, :tell) do
    recipient
    |> lookup
    |> handle_tell(recipient, message)
  end

  defp lookup(recipient) do
    normalized = recipient |> to_atom |> Kernel.to_string() |> downcase
    Registry.lookup(ElitaRegistry, normalized)
  end

  defp handle_ask([{_pid, %{kind: :native}}], recipient, message) do
    Elita.call(to_atom(recipient), message)
  end

  defp handle_ask([{pid, %{kind: :headless}}], _recipient, message) do
    {:ok, response} = ask(pid, message)
    response
  end

  defp handle_ask([], recipient, _message) do
    "unknown: #{recipient}"
  end

  defp handle_tell([{_pid, %{kind: :native}}], recipient, message) do
    Elita.cast(to_atom(recipient), message)
  end

  defp handle_tell([{pid, %{kind: :headless}}], _recipient, message) do
    cast(pid, message)
  end

  defp handle_tell([], recipient, _message) do
    "unknown: #{recipient}"
  end
end
