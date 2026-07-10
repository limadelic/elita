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
    result = check(line, parent, agent_name)
    {data, new_line} = feed(rest, [], parent, agent_name)

    if handled?(result) do
      {"", new_line}
    else
      {eol <> data, new_line}
    end
  end

  defp check(line, parent, agent_name) do
    line
    |> join("")
    |> trim()
    |> dispatch(parent, agent_name)
  end

  defp handled?(result) do
    result == {:handled}
  end

  def dispatch("/exit", parent, _agent_name) do
    send(parent, :exit_wrap)
    :forward
  end

  def dispatch("", _parent, _agent_name) do
    :forward
  end

  def dispatch(input, parent, agent_name) when is_atom(agent_name) do
    route(input, parent, agent_name)
  end

  def dispatch(_input, _parent, _agent_name) do
    :forward
  end

  defp route(input, parent, agent_name) do
    case String.split(input, " ", parts: 2) do
      [_] -> :forward
      [word, rest] -> send_to_puppet(word, rest, parent, agent_name)
    end
  end

  defp send_to_puppet(name, message, _parent, agent_name) do
    atom_name = to_atom(name)

    case target(atom_name) do
      nil ->
        :forward

      puppet_pid ->
        Task.start(fn ->
          try do
            ask(puppet_pid, message) |> puts()
            puts("#{agent_name}> ")
          rescue
            _ -> :ok
          end
        end)

        {:handled}
    end
  end
end
