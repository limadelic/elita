defmodule ElitaTester do
  import ExUnit.Assertions

  def start(agent) do
    Node.start(:"test@127.0.0.1")
    Node.set_cookie(:elita)
    {:ok, pid} = Elita.start_link(agent)
    pid
  end

  def verify(pid, q, expected_strings) do
    response = Elita.act(q, pid)
    Enum.each(expected_strings, &assert(String.contains?(response, &1)))
  end
end