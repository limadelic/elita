defmodule Elita.Infra do
  import Supervisor, only: [start_link: 2]
  import System, only: [get_env: 1]

  def start_link(_arg) do
    start_link(specs(), opts())
  end

  defp specs do
    tapes(get_env("TAPE"))
  end

  defp tapes(nil), do: []
  defp tapes(_), do: [tape()]

  defp tape do
    %{id: Tape.Writer, start: {Tape.Writer, :start_link, [nil]}}
  end

  defp opts,
    do: [
      strategy: :one_for_one,
      name: Elita.Infra,
      max_restarts: 3,
      max_seconds: 30
    ]
end
