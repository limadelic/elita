defmodule ElitaTester do
  import ExUnit.Assertions
  import Node, only: [set_cookie: 1]
  import Elita, only: [start_link: 1]
  import GenServer, only: [call: 3]

  def start agent do
    Node.start :"test@127.0.0.1"
    set_cookie :elita
    start_link agent
  end

  def verify agent, a, q do
    response = call {:global, agent}, {:act, q}, 30000
    IO.puts "Q: #{q}"
    IO.puts "A: #{response}"
    assert String.contains? response, a
  end

end