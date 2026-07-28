defmodule Matrix.Application do
  use Application

  import Supervisor, only: [start_link: 2]

  def start(_type, _args) do
    boot()
  end

  defp boot do
    {:ok, _} = run()
    {:ok, self()}
  end

  defp run do
    start_link(specs(), opts())
  end

  defp specs do
    [tasks()]
  end

  defp tasks do
    {Task.Supervisor, name: Matrix.Tasks}
  end

  defp opts do
    [strategy: :one_for_one, name: Matrix.Supervisor]
  end
end
