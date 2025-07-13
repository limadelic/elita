defmodule Elita.IntegrationTest do
  use ExUnit.Case
  use Plug.Test

  setup do
    # Configure to use mock LLM for tests
    Application.put_env(:elita, :pat_module, Elita.Pat.Mock)
    :ok
  end

  test "POST /agents/greedy returns agent decision" do
    game_state = %{
      "type" => "your_turn",
      "hand" => [[3,6], [5,7], [2,4]],
      "board" => [[6,3], [3,8]],
      "playable_ends" => [6, 8]
    }

    conn = conn(:post, "/agents/greedy", game_state)
    conn = put_req_header(conn, "content-type", "application/json")
    
    response = Elita.Router.call(conn, [])
    
    assert response.status == 200
    
    body = Jason.decode!(response.resp_body)
    assert %{"action" => action} = body
    assert action == "play [6,3]"
  end

  test "POST /agents/greedy handles empty hand" do
    game_state = %{
      "type" => "your_turn", 
      "hand" => [],
      "board" => [[6,3]],
      "playable_ends" => [6, 3]
    }

    conn = conn(:post, "/agents/greedy", game_state)
    conn = put_req_header(conn, "content-type", "application/json")
    
    response = Elita.Router.call(conn, [])
    
    assert response.status == 200
    
    body = Jason.decode!(response.resp_body)
    assert %{"action" => "knock knock"} = body
  end

  test "POST to unknown agent returns 404" do
    conn = conn(:post, "/agents/unknown", %{})
    response = Elita.Router.call(conn, [])
    
    assert response.status == 404
  end
end