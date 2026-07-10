defmodule El.Log do
  import File, only: [mkdir_p!: 1]
  import Path, only: [join: 2]
  import System, only: [pid: 0]

  def setup(name) do
    path = log_path(name)
    mkdir_p!(dir(name))
    path
  end

  defp log_path(name) do
    os_pid = pid()
    join(dir(name), "#{name}_#{os_pid}.log")
  end

  defp dir(_name) do
    home = System.get_env("HOME", "~")
    join(home, ".elita/sessions")
  end
end
