defmodule El.Boot do
  @moduledoc false
  import Node, only: [start: 2]
  import Keyword, only: [get: 3]
  import File, only: [cwd!: 0]
  import Path, only: [basename: 1]
  import El.Host, only: [host: 0]
  import String, only: [contains?: 2]
  import El.Trace, only: [write: 1]
  import El.Run, only: [suffix: 0]

  def go(name \\ :default, opts \\ []) do
    boot(node(name, opts), mode(opts))
  end

  defp mode(opts) do
    %{true => :longnames, false => :shortnames}[
      opts |> get(:host, "127.0.0.1") |> contains?(".")
    ]
  end

  defp node(:default, opts), do: :"#{cwd!() |> basename()}#{suffix()}@#{get(opts, :host, host())}"
  defp node(name, opts), do: :"#{name}#{suffix()}@#{get(opts, :host, host())}"

  defp boot(name, mode) do
    fn -> start(name, mode) end
    |> then(&attempt(&1.(), &1, 1))
    |> act(name, mode)
  end

  defp attempt({:ok, pid}, _fun, _tries), do: {:ok, pid}

  defp attempt({:error, {:already_started, pid}}, _fun, _tries),
    do: {:error, {:already_started, pid}}

  defp attempt({:error, reason}, _fun, _tries) do
    write("boot failed reason=#{inspect(reason)}\n")
    {:error, reason}
  end

  defp act({:ok, _}, name, _) do
    write("boot distribution=#{name} actual_node=#{node()}\n")
    :ok
  end

  defp act({:error, {:already_started, _}}, name, _) do
    write("boot distribution=#{name} status=already_started actual_node=#{node()}\n")
    :taken
  end

  defp act({:error, reason}, _, _) do
    write("boot error: #{inspect(reason)}\n")
    :ok
  end
end
