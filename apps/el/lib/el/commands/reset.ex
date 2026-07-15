defmodule El.Commands.Reset do
  @moduledoc false
  import :os, only: [cmd: 1]
  import File, only: [write!: 2]
  import El.Log, only: [write: 1]

  def cleanup do
    write("shutdown\n")
    reset()
    stty()
  end

  defp reset do
    write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  rescue
    _ -> :ok
  end

  defp stty do
    cmd(~c"stty sane < /dev/tty")
  rescue
    _ -> :ok
  end
end
