defmodule Silkd do
  use GenServer
  alias Jason

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def weave(action, params \\ %{})

  def weave(:navigate, params) do
    with :ok <- validate_host(params["url"]) do
      nav_result = call(:navigate, params)
      Process.sleep(2000)
      snapshot_result = call(:snapshot, %{})

      {numbered, index_map} = number_elements(snapshot_result["snapshot"])
      GenServer.call(__MODULE__, {:store_map, index_map}, 5_000)

      Map.put(nav_result, "snapshot", numbered)
    else
      {:error, reason} -> %{"status" => "error", "message" => reason}
    end
  end

  def weave(:snapshot, _params) do
    snapshot_result = call(:snapshot, %{})

    {numbered, index_map} = number_elements(snapshot_result["snapshot"])
    GenServer.call(__MODULE__, {:store_map, index_map}, 5_000)

    %{"status" => "ok", "snapshot" => numbered}
  end

  def weave(:click, params) when is_map_key(params, "index") do
    selector = GenServer.call(__MODULE__, {:lookup, params["index"]}, 5_000)
    params = Map.put(params, "selector", selector) |> Map.delete("index")
    call(:click, params)
  end

  def weave(:type, params) when is_map_key(params, "index") do
    selector = GenServer.call(__MODULE__, {:lookup, params["index"]}, 5_000)
    params = Map.put(params, "selector", selector) |> Map.delete("index")
    call(:type, params)
  end

  def weave(action, params) do
    call(action, params)
  end

  defp call(action, params) do
    GenServer.call(__MODULE__, {:command, %{action: action, params: params}}, 30_000)
  end

  defp validate_host(url) when is_binary(url) do
    try do
      case :ets.lookup(Mem.table(), "host") do
        [{_, allowed}] -> check_host(URI.parse(url).host, allowed)
        _ -> :ok
      end
    rescue
      _ -> :ok
    end
  end

  defp validate_host(_), do: :ok

  defp check_host(host, allowed) when host == allowed, do: :ok
  defp check_host(host, allowed) do
    case String.ends_with?(host || "", ".#{allowed}") do
      true -> :ok
      false -> {:error, "Host #{host} not allowed. Only #{allowed} permitted."}
    end
  end

  defp number_elements(snapshot) when is_binary(snapshot) do
    case Jason.decode(snapshot) do
      {:ok, tree} -> number_elements(tree)
      _ -> {snapshot, %{}}
    end
  end

  defp number_elements(snapshot) when is_map(snapshot) do
    {elements, _final_index} = walk_tree(snapshot, 1, [])
    numbered = format_numbered(elements)
    index_map = Enum.into(elements, %{}, fn {idx, selector, _desc} -> {idx, selector} end)
    {numbered, index_map}
  end

  defp number_elements(snapshot), do: {inspect(snapshot), %{}}

  defp walk_tree(%{"role" => role, "name" => name} = node, index, acc) when role in ["textbox", "button", "link", "combobox", "searchbox"] do
    selector = build_selector(node)
    new_acc = acc ++ [{index, selector, "#{role}: #{name}"}]

    case node do
      %{"children" => children} when is_list(children) ->
        walk_children(children, index + 1, new_acc)
      _ ->
        {new_acc, index + 1}
    end
  end

  defp walk_tree(%{"children" => children} = _node, index, acc) when is_list(children) do
    walk_children(children, index, acc)
  end

  defp walk_tree(_node, index, acc), do: {acc, index}

  defp walk_children(children, index, acc) do
    Enum.reduce(children, {acc, index}, fn child, {current_acc, current_index} ->
      walk_tree(child, current_index, current_acc)
    end)
  end

  defp build_selector(%{"role" => "link", "name" => name}) do
    first_word = name |> String.split() |> List.first() || ""
    "a:has-text('#{String.slice(first_word, 0..15)}')"
  end

  defp build_selector(%{"name" => name}) when byte_size(name) > 5 do
    "[aria-label*='#{String.slice(name, 0..30)}']"
  end

  defp build_selector(%{"role" => role}), do: "[role='#{role}']"
  defp build_selector(_), do: "[data-unknown='true']"

  defp format_numbered(elements) do
    elements
    |> Enum.map(fn {idx, _selector, desc} -> "[#{idx}] #{desc}" end)
    |> Enum.join("\n")
  end

  @impl true
  def init(_opts) do
    script = Path.join(:code.priv_dir(:elita), "playwright/bridge.js")
    port = Port.open({:spawn, "node #{script}"}, [:binary, :exit_status])

    receive do
      {^port, {:data, data}} ->
        case Jason.decode(data) do
          {:ok, %{"status" => "ready"}} -> {:ok, %{port: port, index_map: %{}}}
          _ -> {:stop, :init_failed}
        end
    after
      10_000 -> {:stop, :timeout}
    end
  end

  @impl true
  def handle_call({:store_map, index_map}, _from, state) do
    {:reply, :ok, Map.put(state, :index_map, index_map)}
  end

  @impl true
  def handle_call({:lookup, index}, _from, state) do
    selector = Map.get(state.index_map, index, "[data-index='#{index}']")
    {:reply, selector, state}
  end

  @impl true
  def handle_call({:command, command}, _from, state) do
    json = Jason.encode!(command)
    Port.command(state.port, "#{json}\n")

    data = collect_response(state.port, "")
    response = Jason.decode!(data)
    {:reply, response, state}
  end

  defp collect_response(port, acc) do
    receive do
      {^port, {:data, chunk}} ->
        new_acc = acc <> chunk
        if String.ends_with?(new_acc, "\n") do
          String.trim(new_acc)
        else
          collect_response(port, new_acc)
        end
    after
      30_000 -> raise "timeout"
    end
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, state) when port == state.port do
    {:stop, {:port_exit, status}, state}
  end

  @impl true
  def terminate(_reason, state) do
    Port.close(state.port)
    :ok
  end
end
