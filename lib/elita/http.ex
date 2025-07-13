defmodule Elita.HTTP do
  @moduledoc """
  HTTP server for agent requests
  """

  def child_spec(_) do
    Bandit.child_spec(
      plug: Elita.Router,
      scheme: :http,
      port: 4000
    )
  end
end

defmodule Elita.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/agents/greedy" do
    case Elita.AgentRunner.decide("greedy", conn.body_params) do
      {:ok, response} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(response))
      
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: reason}))
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end