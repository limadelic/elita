defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum, only: [drop: 2, join: 2]
  import String, only: [split: 2, split: 3, trim: 1, to_atom: 1]
  import El.Distribution, only: [target: 1]
  import El.Puppet, only: [ask: 2]
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
    finalize(result == {:handled}, input, eol, data, line)
  end

  defp finalize(true, _input, _eol, _data, line), do: {"", line}
  defp finalize(false, input, eol, data, line), do: {input <> eol <> data, line}

  defp check(line, parent, agent),
    do: line |> to_string() |> trim() |> dispatch(parent, agent)

  def dispatch("/exit", parent, _agent) do
    send(parent, :exit_wrap)
    :forward
  end

  def dispatch("", _parent, _agent), do: :forward

  def dispatch(input, parent, agent) when is_atom(agent) do
    input |> split(" ", parts: 2) |> route(parent, agent)
  end

  def dispatch(_input, _parent, _agent), do: :forward

  defp route([_], _parent, _agent), do: :forward

  defp route([word, rest], _parent, agent) do
    puppet(word, rest, agent)
  end

  defp route(_, _parent, _agent), do: :forward

  defp puppet(name, message, agent) do
    name |> to_atom() |> target() |> dial(message, agent)
  end

  defp dial(nil, _message, _agent), do: :forward

  defp dial(puppet, message, agent) do
    ask(puppet, message) |> show(agent)
  catch
    :exit, _ -> :forward
  end

  defp show(response, agent) do
    content = response |> split("\n") |> drop(-1) |> join("\n")
    write(:stdio, "#{content}\n#{agent}> ")
    {:handled}
  end
end
