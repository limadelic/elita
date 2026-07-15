defmodule Reply do
  def deliver(agent, text) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :answer, [agent, text])
  rescue
    _ -> :ok
  end
end
