defmodule Tools.Reply do
  import Log, only: [write: 1]
  import String, only: [trim: 1]

  @icon "✨"

  def icon, do: @icon

  def answer(agent, text) when is_binary(text) do
    msg = "#{@icon} #{agent} | #{trim(text)}\n"
    write(msg)
    el(msg)
  end

  def answer(_agent, _text), do: :ok

  defp el(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
