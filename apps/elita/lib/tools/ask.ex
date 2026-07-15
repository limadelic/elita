defmodule Tools.Ask do
  import Log, only: [write: 1]
  import Tools.Sys.Ask, only: [icon: 0]

  def prompt(sender, recipient, question) do
    msg = "#{icon()} #{sender} → #{recipient} | #{question}\n"
    write(msg)
    el(msg)
  end

  defp el(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
