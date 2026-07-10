defmodule El.Log do
  use GenServer
  import File, only: [mkdir_p!: 1, open: 2, cwd!: 0]
  import Path, only: [join: 2]
  import System, only: [pid: 0, get_env: 2]
  import IO, only: [binwrite: 2]
  import GenServer, only: [start_link: 3, cast: 2]
  import Map, only: [new: 1]

  @name :session_logger
  @cfg [type: :file, modes: [:write, :append], formatter: {El.Log.Format, %{}}]

  def setup(name, argv) do
    p = path(name)
    prepare(name, p, argv)
    p
  end

  defp prepare(name, p, argv) do
    mkdir_p!(dir(name))
    start(p)
    boot(p, argv)
    attach(p)
  end

  def write(message) do
    cast(@name, {:write, message})
  rescue
    _ -> :ok
  end

  def start(path) do
    start_link(__MODULE__, path, name: @name)
  rescue
    _ -> :ok
  end

  def init(path) do
    {:ok, file} = open(path, [:write, :append])
    {:ok, file}
  end

  def handle_cast({:write, message}, file) do
    binwrite(file, message)
    {:noreply, file}
  end

  defp boot(_path, argv) do
    write("boot node=#{node()} cwd=#{cwd!()} argv=#{inspect(argv)}\n")
  end

  defp attach(path) do
    :logger.add_handler(:session_handler, :logger_std_h, opts(path))
  rescue
    _ -> :ok
  end

  defp opts(path) do
    %{level: :debug, config: inner(path)}
  end

  defp inner(path) do
    (@cfg ++ [file: String.to_charlist(path)]) |> new()
  end

  defp path(name) do
    join(dir(name), "#{name}_#{pid()}.log")
  end

  defp dir(_name) do
    join(get_env("HOME", "~"), ".elita/sessions")
  end
end
