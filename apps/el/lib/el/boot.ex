defmodule El.Boot do
  @moduledoc false
  import Process, only: [sleep: 1]
  import Node, only: [set_cookie: 1]
  import Keyword, only: [get: 3]
  import File, only: [cwd!: 0]
  import Path, only: [basename: 1]
  import El.Host, only: [host: 0]
  import String, only: [contains?: 2]
  import El.Log, only: [write: 1]

  def start(name \\ :default, opts \\ []) do
    :os.cmd(~c"epmd -daemon")
    boot(node(name, opts), mode(opts))
  end

  defp mode(opts) do
    %{true => :longnames, false => :shortnames}[
      opts |> get(:host, "127.0.0.1") |> contains?(".")
    ]
  end

  defp node(:default, opts), do: :"#{cwd!() |> basename()}@#{get(opts, :host, host())}"
  defp node(name, opts), do: :"#{name}@#{get(opts, :host, host())}"

  defp boot(name, mode),
    do: fn -> Node.start(name, mode) end |> then(&attempt(&1.(), &1, 5)) |> act(name, mode)

  defp attempt({:ok, pid}, _fun, _tries), do: {:ok, pid}

  defp attempt({:error, {:already_started, pid}}, _fun, _tries),
    do: {:error, {:already_started, pid}}

  defp attempt({:error, _reason}, fun, tries) when tries > 1 do
    sleep(200)
    attempt(fun.(), fun, tries - 1)
  end

  defp attempt({:error, reason}, _fun, _tries) do
    write("boot failed reason=#{inspect(reason)}\n")
    {:error, reason}
  end

  defp act({:ok, _}, name, _) do
    write("boot distribution=#{name} actual_node=#{node()}\n")
    cookie(:ok)
  end

  defp act({:error, {:already_started, _}}, name, _) do
    write("boot distribution=#{name} status=already_started actual_node=#{node()}\n")
    cookie(:taken)
  end

  defp act({:error, reason}, _, _) do
    write("boot error: #{inspect(reason)}\n")
    :ok
  end

  defp cookie(val) do
    set_cookie(:elita)
    val
  end
end
