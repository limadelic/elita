defmodule El.Log do
  use GenServer
  import File, only: [mkdir_p!: 1]
  import Path, only: [join: 2]
  import System, only: [pid: 0]

  @name :session_logger

  def setup(name) do
    path = log_path(name)
    mkdir_p!(dir(name))
    start_server(path)
    path
  end

  def write(message) do
    GenServer.cast(@name, {:write, message})
  rescue
    _ -> :ok
  end

  def start_server(path) do
    GenServer.start_link(__MODULE__, path, name: @name)
  rescue
    _ -> :ok
  end

  def init(path) do
    {:ok, file} = File.open(path, [:write, :append])
    {:ok, file}
  end

  def handle_cast({:write, message}, file) do
    IO.write(file, message)
    {:noreply, file}
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
