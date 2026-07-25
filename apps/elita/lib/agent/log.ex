defmodule Agent.Log do
  def reply(name) do
    :erlang.apply(:"Elixir.El.Sessions", :log, [name])
  rescue
    _ -> ""
  end
end
