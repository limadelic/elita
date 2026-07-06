defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]
  alias El.Distribution

  def execute(name \\ :default) do
    execute(name, [
      distribution_start: &Distribution.start/1,
      cmd: &cmd/1,
      run: &run/2
    ])
  end

  def execute(name, deps) when is_list(deps) do
    session_name = resolve_session_name(name)
    ensure_available(deps, session_name)
    launch(String.to_atom(session_name), deps)
  after
    restore()
    cmd(~c"stty sane < /dev/tty")
  end

  defp ensure_available(deps, session_name) do
    result = Keyword.get(deps, :distribution_start).(session_name)
    if result == :taken do
      IO.puts("session #{session_name} already live — el tell #{session_name} <msg>, or /exit it")
      System.halt(1)
    end
  end

  defp launch(process_name, deps) do
    cmd_fn = Keyword.get(deps, :cmd)
    cmd_fn.(~c"stty raw -echo -isig < /dev/tty")
    run_fn = Keyword.get(deps, :run)
    run_fn.(process_name, get_size: &read_terminal_size/0, input: &translate_newline/1)
  end

  defp read_terminal_size, do: fallback([read_env(), read_stty(), {24, 80}])
  defp fallback([nil | rest]), do: fallback(rest)
  defp fallback([size | _]), do: size

  defp read_env do
    maybe_parse_env(System.get_env("EL_ROWS"), System.get_env("EL_COLS"))
  end

  defp maybe_parse_env(rows, cols) when is_binary(rows) and is_binary(cols), do: parse_env_size(rows, cols)
  defp maybe_parse_env(_, _), do: nil

  defp parse_env_size(rows, cols) do
    with {row, ""} <- Integer.parse(rows),
         {col, ""} <- Integer.parse(cols),
         true <- row > 0 and col > 0 do
      {row, col}
    else
      _ -> nil
    end
  rescue
    _ -> nil
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

  defp resolve_session_name(:default), do: File.cwd!() |> Path.basename()
  defp resolve_session_name(name) when is_binary(name), do: name

end
