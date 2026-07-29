defmodule El.Signal do
  @behaviour :gen_event
  def activate do
    :os.set_signal(:sigterm, :handle)
    :gen_event.add_handler(:erl_signal_server, __MODULE__, [])
  end

  @impl true
  def init(_), do: {:ok, []}
  @impl true
  def handle_event(:sigterm, state) do
    :init.stop()
    {:ok, state}
  end

  @impl true
  def handle_event(_, state), do: {:ok, state}
  @impl true
  def handle_call(_, state), do: {:ok, :ok, state}
end
