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
      case net_adm.names() do
        {:ok, names} -> names
        names when is_list(names) -> names
        _ -> []
      end
    rescue
      _ -> []
    catch
      _ -> []
    end
  end

  defp default_filter({name, _port}) do
    name_string(name)
    |> String.starts_with?("claude_")
  end

  defp default_extract({name, _port}) do
    name_string(name)
    |> String.replace_prefix("claude_", "")
  end

  defp name_string(name) when is_atom(name) do
    Atom.to_string(name)
  end

  defp name_string(name) when is_list(name) do
    List.to_string(name)
  end

  defp name_string(name) when is_binary(name) do
    name
  end

  defp default_ping(name) do
    node_atom = node_to_atom(name)
    Node.ping(node_atom)
  end

  defp node_to_atom(name) when is_atom(name) do
    name
  end

  defp node_to_atom(name) when is_list(name) do
    name
    |> List.to_string()
    |> String.to_atom()
  end

  defp node_to_atom(name) when is_binary(name) do
    String.to_atom(name)
  end
end
