defmodule El.Commands.Ls do
  import IO, only: [puts: 1]
  import El.Host, only: [host: 0]

  def execute(opts \\ []) do
    {Keyword.get(opts, :net_adm, :net_adm), Keyword.get(opts, :host, nil),
     Keyword.get(opts, :filter, &default_filter/1), Keyword.get(opts, :ping, &default_ping/2),
     Keyword.get(opts, :extract, &default_extract/1)}
    |> call_build()
  end

  defp call_build({net_adm, host, filter, ping, extract}) do
    names = safe_get_names(net_adm, host)
    display(build_sessions(names, host, filter, ping, extract))
  end

  defp build_sessions(names, host, filter, ping, extract) do
    names
    |> Enum.filter(fn entry -> alive?(entry, filter, host, ping) end)
    |> Enum.map(extract)
  end

  defp alive?(entry, filter, host, ping) do
    filter.(entry) && ping.(elem(entry, 0), host) == :pong
  end

  defp display([]), do: puts("no sessions")
  defp display(sessions), do: Enum.each(sessions, &puts/1)

  defp safe_get_names(net_adm, host) do
    call_names(net_adm, host) |> handle_names()
  rescue
    _ -> []
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

  defp default_ping(name, host) do
    node_atom = node_to_atom(name, host)
    Node.set_cookie(:elita)
    Node.ping(node_atom)
  end

  defp node_to_atom(name, nil) do
    name_str = name_string(name)
    String.to_atom("#{name_str}@#{host()}")
  end

  defp node_to_atom(name, host) do
    name_str = name_string(name)
    String.to_atom("#{name_str}@#{host}")
  end
end
