defmodule Matrix.Pty.Boot do
  @moduledoc false
  import Matrix.Pty.Env
  import System, only: [get_env: 2]

  def launch(port, cmd, size) do
    argv = args(size, cmd)
    port.open({:spawn_executable, "/usr/bin/script"}, opts(argv))
  end

  defp opts(argv) do
    [:binary, :stream, :exit_status, {:args, argv}, {:env, env()}]
  end

  defp env do
    path = get_env("PATH", "")
    unset() ++ [{~c"PATH", to_charlist(path)}]
  end

  defp args({rows, cols}, cmd) do
    stty = "stty rows #{rows} cols #{cols}; stty raw -echo -isig;"
    argv(:os.type(), stty, cmd)
  end

  defp argv({:unix, :darwin}, stty, cmd) do
    ["-q", "/dev/null", "sh", "-c", "#{stty} exec #{cmd}"]
  end

  defp argv({:unix, _}, stty, cmd) do
    ["-q", "-c", "#{stty} exec #{cmd}", "/dev/null"]
  end
end
