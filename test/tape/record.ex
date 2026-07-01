defmodule Tape.Record do
  alias Tape.Store

  def handle(body, name, fun) do
    response = fun.()
    Store.append_live(normalize(body), response)
    response
  end

  defp normalize(body) do
    Map.take(body, [:system, :messages, :tools])
  end
end
