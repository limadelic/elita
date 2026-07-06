defmodule El.Commands.Ls do
  import IO, only: [puts: 1]

  def execute(opts \\ []) do
    net_adm = Keyword.get(opts, :net_adm, :net_adm)
    filter = Keyword.get(opts, :filter, &default_filter/1)
    extract = Keyword.get(opts, :extract, &default_extract/1)
    ping = Keyword.get(opts, :ping, &default_ping/1)

    names = safe_get_names(net_adm)

    sessions = names
    |> Enum.filter(filter)
    |> Enum.filter(fn entry -> ping.(elem(entry, 0)) == :pong end)
    |> Enum.map(extract)

    if Enum.empty?(sessions) do
      puts("no sessions")
    else
      Enum.each(sessions, &puts/1)
    end
  end

  defp safe_get_names(net_adm) do
    try do
      if is_atom(net_adm) do
        net_adm.names()
      else
        net_adm.names()
      end
    rescue
      _ -> []
    catch
      _ -> []
    end
  end

  defp default_filter({name, _port}) do
    Atom.to_string(name)
    |> String.starts_with?("claude_")
  end

  defp default_extract({name, _port}) do
    Atom.to_string(name)
    |> String.replace_prefix("claude_", "")
  end

  defp default_ping(name) do
    Node.ping(name)
  end
end
