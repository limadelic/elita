defmodule Matrix.Wrap.Route do
  @moduledoc false
  import String, only: [split: 3, trim: 1]
  import El.Wrap.Remote, only: [deliver: 3, tell: 3]

  def check(line, parent, agent),
    do: line |> to_string() |> trim() |> dispatch(parent, agent)

  def dispatch("/exit", parent, _agent) do
    send(parent, :exit_wrap)
    :forward
  end

  def dispatch("", _parent, _agent), do: :forward

  def dispatch("@" <> rest, _parent, agent) when is_atom(agent) do
    rest |> split(">", parts: 2) |> remote(agent)
  end

  def dispatch(input, _parent, agent) when is_atom(agent) do
    input |> split(" ", parts: 2) |> implicit(agent)
  end

  def dispatch(_input, _parent, _agent), do: :forward

  defp remote([name, message], agent) do
    spawn(fn -> deliver(name, message, agent) end)
    {:handled}
  end

  defp remote(_, _agent), do: :forward

  defp implicit(["tell", names_msg], agent) do
    names_msg |> split(" ", parts: 2) |> sender(agent)
  end

  defp implicit([word, rest], agent) do
    spawn(fn -> deliver(word, rest, agent) end)
    {:handled}
  end

  defp implicit(_, _agent), do: :forward

  defp sender([name, message], agent) do
    spawn(fn -> tell(name, message, agent) end)
    {:handled}
  end

  defp sender(_, _agent), do: :forward
end
