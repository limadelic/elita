defmodule El.Commands.Claude do
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]

  def execute do
    get_size = &read_terminal_size/0
    cmd(~c"stty raw -echo -isig < /dev/tty")
    run(:claude, get_size: get_size)
  after
    cmd(~c"stty sane < /dev/tty")
  end

  defp read_terminal_size do
    System.cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse_size()
  rescue
    _ -> {24, 80}
  end

  defp parse_size({output, 0}) do
    String.trim(output)
    |> String.split()
    |> extract_size()
  end

  defp parse_size(_), do: {24, 80}

  defp extract_size([rows, cols]), do: {String.to_integer(rows), String.to_integer(cols)}
  defp extract_size(_), do: {24, 80}
end
