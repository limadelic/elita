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
      feed(chunk, line, parent, agent_name)
    end)
  end

  defp feed(<<>>, line, _parent, _agent_name) do
    {"", line}
  end

  defp feed(<<13, rest::binary>>, line, parent, agent_name) do
    eol(line, rest, parent, agent_name, "\r")
  end

  defp feed(<<10, rest::binary>>, line, parent, agent_name) do
    eol(line, rest, parent, agent_name, "\n")
  end

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
    check(line, parent, agent_name)
    {data, new_line} = feed(rest, [], parent, agent_name)
    {eol <> data, new_line}
  end

  defp check(line, parent, agent_name) do
    line
    |> join("")
    |> trim()
    |> dispatch(parent, agent_name)
  end

  def dispatch("/exit", parent, _agent_name) do
    send(parent, :exit_wrap)
  end

  def dispatch("", _parent, _agent_name) do
    :ok
  end

  def dispatch(input, _parent, agent_name) when is_atom(agent_name) do
    route(input, agent_name)
  end

  def dispatch(_input, _parent, _agent_name) do
    :ok
  end

  defp route(input, _agent_name) do
    case String.split(input, " ", parts: 2) do
      [_] -> :ok
      [word, rest] -> send_to_puppet(word, rest)
    end
  end

  defp send_to_puppet(name, message) do
    atom_name = to_atom(name)
    case target(atom_name) do
      nil -> :ok
      puppet_pid ->
        try do
          ask(puppet_pid, message) |> puts()
          :ok
        rescue
          _ -> :ok
        end
    end
  end
end
