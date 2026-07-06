defmodule El.Commands.Claude do
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]
  import El.Distribution, only: [start: 0]

  def execute do
    get_size = &read_terminal_size/0
    cmd(~c"stty raw -echo -isig < /dev/tty")
    start()
    run(:claude, get_size: get_size)
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
end
