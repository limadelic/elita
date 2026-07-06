defmodule El.Commands.Ls do
  import IO, only: [puts: 1]

  def execute(opts \\ []) do
    {Keyword.get(opts, :net_adm, :net_adm), Keyword.get(opts, :host, nil),
     Keyword.get(opts, :filter, &default_filter/1), Keyword.get(opts, :ping, &default_ping/1),
     Keyword.get(opts, :extract, &default_extract/1)}
    |> call_build()
  end

  defp call_build({net_adm, host, filter, ping, extract}) do
    display(build_sessions(safe_get_names(net_adm, host), filter, ping, extract))
  end

  defp build_sessions(names, filter, ping, extract) do
    names
    |> Enum.filter(filter)
    |> Enum.filter(fn entry -> ping.(elem(entry, 0)) == :pong end)
    |> Enum.map(extract)
  end

  defp display([]), do: puts("no sessions")
  defp display(sessions), do: Enum.each(sessions, &puts/1)

  defp safe_get_names(net_adm, host) do
    wrap_call(fn -> handle_names(call_names(net_adm, host)) end)
  end

  defp wrap_call(fun) do
    try do
      fun.()
    rescue
      _ -> []
    catch
      _ -> []
    end
  end

  defp handle_names({:ok, names}), do: names
  defp handle_names(names) when is_list(names), do: names
  defp handle_names(_), do: []

  defp call_names(net_adm, nil), do: net_adm.names()
  defp call_names(net_adm, host), do: net_adm.names(host)

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
