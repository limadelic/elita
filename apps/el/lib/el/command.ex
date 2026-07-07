defmodule El.Command do
  @moduledoc false

  import IO, only: [puts: 1]
  import Node, only: [connect: 1]

  alias El.Commands.Ask
  alias El.Commands.Tell
  alias El.Commands.Claude
  alias El.Commands.Ls
  alias El.Distribution
  alias El.RPC

  def ls do
    Distribution.start()
    query() |> handle()
  end

  defp handle({:ok, output}), do: puts(output)
  defp handle(:error), do: Ls.execute()

  def ask(agent, msg), do: Ask.execute(agent, msg)
  def tell(agent, msg), do: Tell.execute(agent, msg)
  def claude(name), do: Claude.execute(name)
  def daemon, do: Distribution.boot_daemon()

  defp query do
    connect(:"elita@127.0.0.1") |> safe_fetch()
  end

  defp safe_fetch(bool) do
    fetch(bool)
  rescue
    _ -> :error
  end

  defp fetch(true) do
    cwd = File.cwd!()
    output = :erpc.call(:"elita@127.0.0.1", RPC, :dispatch, [["ls"], cwd])
    {:ok, output}
  end

  defp fetch(_), do: :error
end
