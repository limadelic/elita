defmodule Agent.Kind.Native do
  @behaviour Agent.Kind
  import String, only: [to_atom: 1]
  import Elita, only: [request: 2, dispatch: 2]

  @impl true
  def ask([{_pid, %{kind: :native}}], recipient, message) do
    request(to_atom(recipient), message)
  end

  @impl true
  def forward([{_pid, %{kind: :native}}], recipient, message) do
    dispatch(to_atom(recipient), message)
  end
end
