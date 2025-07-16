defmodule Elita.IntegrationTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  setup do
    try do
      :meck.new(Elita.Pat, [:passthrough])
    catch
      :error, {:already_started, _} -> :ok
    end
    
    try do
      :meck.new(Elita.Loader, [:passthrough])
    catch
      :error, {:already_started, _} -> :ok
    end
    
    :meck.expect(Elita.Loader, :agent, fn("greedy") -> 
      %{
        name: "Greedy",
        role: "Test role",
        goals: "Test goals", 
        instructions: "Test instructions",
        examples: "Test examples"
      }
    end)
    
    on_exit(fn -> 
      try do
        :meck.unload(Elita.Pat)
        :meck.unload(Elita.Loader)
      catch
        :error, _ -> :ok
      end
    end)
    :ok
  end

  test "POST /agents/greedy returns agent decision" do
    :meck.expect(Elita.Pat, :say, fn(_prompt) -> {:ok, "play [6,3]"} end)
    
    game_state = %{
      "type" => "your_turn",
      "hand" => [[3,6], [5,7], [2,4]],
      "board" => [[6,3], [3,8]],
      "playable_ends" => [6, 8]
    }

    conn = conn(:post, "/agents/greedy", game_state)
    conn = put_req_header(conn, "content-type", "application/json")
    
    response = Api.Router.call(conn, [])
    
    assert response.status == 200
    
    body = Jason.decode!(response.resp_body)
    assert body == "play [6,3]"
  end

  test "POST /agents/greedy handles empty hand" do
    :meck.expect(Elita.Pat, :say, fn(_prompt) -> {:ok, "knock knock"} end)
    
    game_state = %{
      "type" => "your_turn", 
      "hand" => [],
      "board" => [[6,3]],
      "playable_ends" => [6, 3]
    }

    conn = conn(:post, "/agents/greedy", game_state)
    conn = put_req_header(conn, "content-type", "application/json")
    
    response = Api.Router.call(conn, [])
    
    assert response.status == 200
    
    body = Jason.decode!(response.resp_body)
    assert body == "knock knock"
  end

end