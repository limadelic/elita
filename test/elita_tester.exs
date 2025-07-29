defmodule ElitaTester do
  import ExUnit.Assertions
  import Node, only: [set_cookie: 1]
  import Elita, only: [start_link: 1]
  import GenServer, only: [call: 2]
  import Enum, only: [each: 2]

  def start agent do
    Node.start :"test@127.0.0.1"
    set_cookie :elita
    start_link agent
  end

  def verify(agent, q, a) when is_binary(a) do
    response = call {:global, agent}, {:act, q}
    assert String.contains? response, a
  end

  def verify(agent, q, a) when is_list(a) do
    response = call {:global, agent}, {:act, q}
    each a, &assert(String.contains? response, &1)
  end
end