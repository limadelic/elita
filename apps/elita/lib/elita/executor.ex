defmodule Elita.Executor do
  def call({"set", %{"field" => field, "value" => value}}, state) do
    {"stored #{field}", %{state | memory: Map.put(state.memory, field, value)}}
  end

  def call({"say", %{"message" => message}}, state) do
    Phoenix.PubSub.broadcast(Elita.PubSub, state.group, {:intercom, state.name, message})
    {"broadcasted: #{message}", state}
  end

  def call({name, _params}, state) do
    {"unknown tool: #{name}", state}
  end
end