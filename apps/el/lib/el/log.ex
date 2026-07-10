defmodule El.Log do
  use GenServer
  import File, only: [mkdir_p!: 1]
  import Path, only: [join: 2]
  import System, only: [pid: 0]

  @name :session_logger

  def setup(name, argv) do
    path = log_path(name)
    mkdir_p!(dir(name))
    start_server(path)
    boot(path, argv)
    attach_handler(path)
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

  defp boot(_path, argv) do
    import File, only: [cwd!: 0]
    write("boot node=#{node()} cwd=#{cwd!()} argv=#{inspect(argv)}\n")
  end

  defp attach_handler(path) do
    :logger.add_handler(:session_handler, :logger_std_h, %{
      level: :debug,
      config: %{
        type: :file,
        file: String.to_charlist(path),
        modes: [:write, :append],
        formatter: {El.Log.Format, %{}}
      }
    })
  rescue
    _ -> :ok
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
