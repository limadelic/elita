defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum
  import String
  import El.Distribution, only: [target: 1]
  import El.Puppet, only: [ask: 2]
  import IO, only: [write: 2]
  import El.Log, only: [write: 1]

  def open(parent, agent_name \\ nil) do
    {:ok, pid} = start_link(fn -> {[], parent, agent_name} end)
    write("input handler opened for #{inspect(agent_name)}\n")
    pid
  rescue
    e ->
      write("input open error: #{inspect(e)}\n")
      raise e
  end

  def encode(buf, chunk) do
    get_and_update(buf, fn {line, parent, agent_name} ->
      {data, new_line} = feed(chunk, line, parent, agent_name)
      {data, {new_line, parent, agent_name}}
    end)
  rescue
    e ->
      write("encode error: #{inspect(e)}\n")
      raise e
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
    input_str = line |> join("")
    write("input line: #{inspect(input_str)}\n")
    result = check(line, parent, agent_name)
    write("dispatch result: #{inspect(result)}\n")
    {data, new_line} = feed(rest, [], parent, agent_name)
    finalize(result == {:handled}, eol, data, new_line)
  end

  defp finalize(true, _eol, _data, new_line), do: {"", new_line}
  defp finalize(false, eol, data, new_line), do: {eol <> data, new_line}

  defp check(line, parent, agent_name) do
    line |> join("") |> trim() |> dispatch(parent, agent_name)
  end

  def dispatch("/exit", parent, agent_name) do
    write("shutdown reason=exit_received in #{inspect(agent_name)}\n")
    send(parent, :exit_wrap)
    :forward
  rescue
    e ->
      write("exit dispatch error: #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  def dispatch("", _parent, _agent_name), do: :forward

  def dispatch(input, parent, agent_name) when is_atom(agent_name) do
    input |> String.split(" ", parts: 2) |> route(parent, agent_name)
  end

  def dispatch(_input, _parent, _agent_name), do: :forward

  defp route([_], _parent, _agent_name) do
    write("route decision: forward (single word)\n")
    :forward
  end

  defp route([word, rest], _parent, agent_name) do
    write("route decision: puppet #{word}\n")
    puppet(word, rest, agent_name)
  end

  defp route(_, _parent, _agent_name) do
    write("route decision: forward (no split)\n")
    :forward
  end

  defp puppet(name, message, agent_name) do
    write("routing #{name} -> #{message}\n")
    name |> to_atom() |> target() |> dial(message, agent_name)
  rescue
    e ->
      write("puppet routing error: #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  defp dial(nil, _message, _agent_name) do
    write("dial failed: no puppet found\n")
    :forward
  end

  defp dial(puppet_pid, message, agent_name) do
    write("dial start #{inspect(puppet_pid)} msg: #{message}\n")
    result = ask(puppet_pid, message)
    write("dial result received, formatting\n")
    result |> format(agent_name) |> output()
    {:handled}
  rescue
    e ->
      write("dial error: #{inspect(e)}\n")
      :forward
  catch
    :exit, reason ->
      write("dial caught exit: #{inspect(reason)}\n")
      :forward
  end

  defp format(response, agent_name) do
    content = response |> String.split("\n") |> drop(-1) |> join("\n")
    "#{content}\n#{agent_name}> "
  end

  defp output(data) do
    write(:stdio, data)
  rescue
    _ -> :ok
  end
end
