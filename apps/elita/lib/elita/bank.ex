defmodule Elita.Bank do
  use GenServer

  import GenServer, only: [start_link: 2]

  def start_link(_arg) do
    start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    :ets.new(:elita_vault, [:named_table, :set, :public, {:read_concurrency, true}])
    {:ok, nil}
  end
end
