defmodule El.Run do
  import Application, only: [get_env: 3]
  import System, only: [get_env: 1]

  def suffix do
    expand("-")
  end

  def expand(prefix) do
    id() |> build(prefix)
  end

  defp build("", _prefix), do: ""
  defp build(run, prefix), do: "#{prefix}#{run}"

  def id do
    get_env(:elita, :run, "")
  end

  def address do
    :"elita#{suffix()}@127.0.0.1"
  end

  def options,
    do: %{
      tape: get_env("TAPE"),
      live: get_env("LIVE"),
      cassette: get_env("CASSETTE"),
      cassette_dir: get_env("CASSETTE_DIR")
    }
end
