defmodule Silkd do
  use GenServer
  alias Jason

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def navigate(url), do: call(:navigate, %{url: url})
  def content, do: call(:content, %{})
  def click(selector, opts \\ []), do: call(:click, params(selector, opts))
  def type(selector, text), do: call(:type, %{selector: selector, text: text})
  def screenshot, do: call(:screenshot, %{})
  def close, do: call(:close, %{})

  defp call(action, params) do
    GenServer.call(__MODULE__, {:command, %{action: action, params: params}}, 30_000)
  end

  defp params(selector, opts) do
    Map.merge(%{selector: selector}, Map.new(opts))
  end

  @impl true
  def init(_opts) do
    script = Path.join(:code.priv_dir(:elita), "playwright/bridge.js")
    port = Port.open({:spawn, "node #{script}"}, [:binary, :exit_status])

    receive do
      {^port, {:data, data}} ->
        case Jason.decode(data) do
          {:ok, %{"status" => "ready"}} -> {:ok, %{port: port}}
          _ -> {:stop, :init_failed}
        end
    after
      10_000 -> {:stop, :timeout}
    end
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
