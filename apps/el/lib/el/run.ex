defmodule El.Run do
  import System, only: [get_env: 2]
  import Path, only: [join: 1]

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

  def file do
    home = get_env("HOME", get_env("USERPROFILE", "."))
    join([home, ".elita", "peers#{suffix()}"])
  end
end
