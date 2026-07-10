defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum
  import String
  import El.Distribution, only: [target: 1]
  import El.Puppet, only: [ask: 2]
  import IO, only: [puts: 1]

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
  defp feed(<<13, rest::binary>>, line, parent, agent_name), do: eol(line, rest, parent, agent_name, "\r")
  defp feed(<<10, rest::binary>>, line, parent, agent_name), do: eol(line, rest, parent, agent_name, "\n")

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
    result = check(line, parent, agent_name)
    {data, new_line} = feed(rest, [], parent, agent_name)
    finalize(result == {:handled}, eol, data, new_line)
  end

  defp finalize(true, _eol, _data, new_line), do: {"", new_line}
  defp finalize(false, eol, data, new_line), do: {eol <> data, new_line}

  defp check(line, parent, agent_name) do
    line |> join("") |> trim() |> dispatch(parent, agent_name)
  end

  def dispatch("/exit", parent, _agent_name) do
    send(parent, :exit_wrap)
    :forward
  end

  def dispatch("", _parent, _agent_name), do: :forward
  def dispatch(input, parent, agent_name) when is_atom(agent_name), do: route(input, parent, agent_name)
  def dispatch(_input, _parent, _agent_name), do: :forward

  defp route(input, parent, agent_name) do
    input
    |> String.split(" ", parts: 2)
    |> process(parent, agent_name)
  end

  defp process([_], _parent, _agent_name), do: :forward
  defp process([word, rest], parent, agent_name) do
    invoke(word, rest, parent, agent_name)
  end

  defp invoke(name, message, _parent, agent_name) do
    name
    |> to_atom()
    |> target()
    |> execute(message, agent_name)
  end

  defp execute(nil, _message, _agent_name), do: :forward
  defp execute(puppet_pid, message, agent_name) do
    Task.start(fn -> converse(puppet_pid, message, agent_name) end)
    {:handled}
  end

  defp converse(puppet_pid, message, agent_name) do
    ask(puppet_pid, message) |> puts()
    puts("#{agent_name}> ")
  end
end
