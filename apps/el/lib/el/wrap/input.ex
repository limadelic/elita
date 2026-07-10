defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum, only: [drop: 2]
  import String, only: [split: 3, trim: 1]
  import El.Wrap.Remote, only: [deliver: 3]
  import IO, only: [write: 2]

  def open(parent, agent \\ nil) do
    {:ok, pid} = start_link(fn -> {[], parent, agent} end)
    pid
  end

  def encode(buf, chunk) do
    get_and_update(buf, fn {line, parent, agent} ->
      {data, line} = feed(chunk, line, parent, agent)
      {data, {line, parent, agent}}
    end)
  end

  defp feed(<<>>, line, _parent, _agent), do: {"", line}

  defp feed(<<13, rest::binary>>, line, parent, agent),
    do: eol(line, rest, parent, agent, "\r")

  defp feed(<<10, rest::binary>>, line, parent, agent),
    do: eol(line, rest, parent, agent, "\n")

  defp feed(<<byte, rest::binary>>, line, parent, agent) when byte in [8, 127] do
    feed(rest, backspace(line), parent, agent)
  end

  defp feed(<<char::utf8, rest::binary>>, line, parent, agent) do
    feed(rest, line ++ [char], parent, agent)
  end

  defp feed(<<_, rest::binary>>, line, parent, agent) do
    feed(rest, line, parent, agent)
  end

  defp backspace([]), do: []
  defp backspace(line), do: drop(line, -1)

  defp eol(line, rest, parent, agent, eol) do
    input = to_string(line)
    result = check(line, parent, agent)
    {data, line} = feed(rest, [], parent, agent)
    finalize(result == {:handled}, input, line, agent, {eol, data})
  end

  defp finalize(true, input, line, agent, {eol, _data}) do
    {input <> eol <> "#{agent}> ", line}
  end

  defp finalize(false, input, line, _agent, {eol, data}) do
    {input <> eol <> data, line}
  end

  defp check(line, parent, agent),
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
    deliver(name, message, agent) |> prompt(agent)
  end

  defp remote(_, _agent), do: :forward

  defp implicit([word, rest], agent),
    do: deliver(word, rest, agent) |> prompt(agent)

  defp implicit(_, _agent), do: :forward

  defp prompt({:handled}, agent) do
    write(:stdio, "#{agent}> ")
    {:handled}
  end

  defp prompt(:forward, _agent), do: :forward
end
