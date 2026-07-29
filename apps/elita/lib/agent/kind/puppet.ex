defmodule Agent.Kind.Puppet do
  @behaviour Agent.Kind
  import Agent.Session, only: [ask: 2, forward: 2]

  @impl true
  def ask([{pid, %{kind: kind}}], _recipient, message)
      when kind in [:headless, :puppet] do
    {:ok, response} = ask(pid, message)
    response
  end

  @impl true
  def forward([{pid, %{kind: kind}}], _recipient, message)
      when kind in [:headless, :puppet] do
    forward(pid, message)
  end
end
