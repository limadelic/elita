defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum, only: [drop: 2, join: 2]
  import String, only: [split: 2, split: 3, trim: 1, to_atom: 1]
  import El.Distribution, only: [target: 1]
  import El.Puppet, only: [ask: 2]
  import IO, only: [write: 2]

  def open(parent, agent_name \\ nil) do
    {:ok, pid} = start_link(fn -> {[], parent, agent_name} end)
    pid
  end

  def encode(buf, chunk) do
    get_and_update(buf, fn {line, parent, agent_name} ->
      {data, new_line} = feed(chunk, line, parent, agent_name)
      {data, {new_line, parent, agent_name}}
    end)
  end

  defp feed(<<>>, line, _parent, _agent_name), do: {"", line}

  defp feed(<<13, rest::binary>>, line, parent, agent_name),
    do: eol(line, rest, parent, agent_name, "\r")

  defp feed(<<10, rest::binary>>, line, parent, agent_name),
    do: eol(line, rest, parent, agent_name, "\n")

  defp feed(<<byte, rest::binary>>, line, parent, agent_name) when byte in [8, 127] do
    chars = backspace(line)
    feed(rest, chars, parent, agent_name)
  end

  defp feed(<<char::utf8, rest::binary>>, line, parent, agent_name) do
    feed(rest, line ++ [char], parent, agent_name)
  end

  defp feed(<<_, rest::binary>>, line, parent, agent_name) do
    feed(rest, line, parent, agent_name)
  end

  defp backspace([]), do: []
  defp backspace(line), do: drop(line, -1)

  defp eol(line, rest, parent, agent_name, eol) do
    input_str = to_string(line)
    result = check(line, parent, agent_name)
    {data, new_line} = feed(rest, [], parent, agent_name)
    finalize(result == {:handled}, input_str, eol, data, new_line)
  end

  defp finalize(true, _input_str, _eol, _data, new_line), do: {"", new_line}
  defp finalize(false, input_str, eol, data, new_line), do: {input_str <> eol <> data, new_line}

  defp check(line, parent, agent_name),
    do: line |> to_string() |> trim() |> dispatch(parent, agent_name)

  def dispatch("/exit", parent, _agent_name) do
    send(parent, :exit_wrap)
    :forward
  end

  def dispatch("", _parent, _agent_name), do: :forward

  def dispatch(input, parent, agent_name) when is_atom(agent_name) do
    input |> split(" ", parts: 2) |> route(parent, agent_name)
  end

  def dispatch(_input, _parent, _agent_name), do: :forward

  defp route([_], _parent, _agent_name), do: :forward

  defp route([word, rest], _parent, agent_name) do
    puppet(word, rest, agent_name)
  end

  defp route(_, _parent, _agent_name), do: :forward

  defp puppet(name, message, agent_name) do
    name |> to_atom() |> target() |> dial(message, agent_name)
  end

  defp dial(nil, _message, _agent_name), do: :forward

  defp dial(puppet_pid, message, agent_name) do
    ask(puppet_pid, message) |> format(agent_name) |> output()
  rescue
    _ -> :forward
  catch
    :exit, _ -> :forward
  end

  defp output(d) do
    write(:stdio, d)
    {:handled}
  end

  defp format(response, agent_name) do
    content = response |> split("\n") |> drop(-1) |> join("\n")
    "#{content}\n#{agent_name}> "
  end
end
