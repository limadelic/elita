defmodule El.Run do
  import System, only: [get_env: 2]

  def suffix do
    expand("-")
  end

  def expand(prefix) do
    id() |> build(prefix)
  end

  defp build("", _prefix), do: ""
  defp build(run, prefix), do: "#{prefix}#{run}"

  def id do
    get_env("ELITA_RUN", "")
  end

  def address do
    :"elita#{suffix()}@127.0.0.1"
  end
end
