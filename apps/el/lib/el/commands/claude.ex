defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]
  alias El.Distribution

  def execute(name \\ :default) do
    session_name = resolve_session_name(name)
    node_name = :"claude_#{session_name}@127.0.0.1"
    process_name = String.to_atom(session_name)

    Node.set_cookie(:elita)

    if node_collision?(node_name) do
      IO.puts("session #{session_name} already live — el tell #{session_name} <msg>, or /exit it")
      System.halt(1)
    end

    get_size = &read_terminal_size/0
    input = &translate_newline/1
    cmd(~c"stty raw -echo -isig < /dev/tty")
    Distribution.start(session_name)
    run(process_name, get_size: get_size, input: input)
  after
    restore()
    cmd(~c"stty sane < /dev/tty")
  end

  defp read_terminal_size do
    read_env() || read_stty() || {24, 80}
  end

  defp read_env do
    case {System.get_env("EL_ROWS"), System.get_env("EL_COLS")} do
      {rows, cols} when is_binary(rows) and is_binary(cols) ->
        with {row, ""} <- Integer.parse(rows),
             {col, ""} <- Integer.parse(cols),
             true <- row > 0 and col > 0 do
          {row, col}
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp read_stty do
    System.cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse_size()
  rescue
    _ -> nil
  end

  defp parse_size({output, 0}) do
    String.trim(output)
    |> String.split()
    |> extract_size()
  end

  defp parse_size(_), do: nil

  defp extract_size([rows, cols]) do
    row = String.to_integer(rows)
    col = String.to_integer(cols)
    if row > 0 and col > 0, do: {row, col}, else: nil
  rescue
    _ -> nil
  end

  defp extract_size(_), do: nil

  defp restore do
    File.write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  rescue
    _ -> :ok
  end

  defp translate_newline(chunk) do
    String.replace(chunk, "\n", "\r")
  end

  defp resolve_session_name(:default) do
    File.cwd!()
    |> Path.basename()
  end

  defp resolve_session_name(name) when is_binary(name) do
    name
  end

  defp node_collision?(node_name) do
    case Node.ping(node_name) do
      :pong -> true
      :pang -> false
    end
  rescue
    _ -> false
  end
end
