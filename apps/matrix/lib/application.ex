defmodule Matrix.Application do
  use Application

  import Supervisor, only: [start_link: 2]
  import Matrix.Pty.Retry, only: [validate: 0]

  def start(_type, _args) do
    validate()
    boot()
  end

  defp boot do
    {:ok, supervisor} = run()
    {:ok, supervisor}
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

  defp opts, do: defaults()

  defp defaults,
    do: [
      strategy: :one_for_one,
      name: Matrix.Supervisor,
      max_restarts: 3,
      max_seconds: 60
    ]
end
