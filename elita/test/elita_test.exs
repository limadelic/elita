defmodule ElitaTest do
  use ExUnit.Case

  setup do
    Node.start(:"test@127.0.0.1")
    Node.set_cookie(:elita)
    :ok
  end

  test "greet" do
    {:ok, pid} = Elita.start_link(:greet)
    
    response = Elita.act(pid, "hello")
    
    assert is_binary(response)
    assert String.length(response) > 0
  end
end