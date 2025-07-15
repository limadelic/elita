defmodule Api.Router do
  use Plug.Router
  alias Elita.Agent

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/agents/:name" do
    case Agent.decide(name, conn.body_params) do
      {:ok, response} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(response))
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: reason}))
    end
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end

  def child_spec(_) do
    Bandit.child_spec(
      plug: __MODULE__,
      scheme: :http,
      port: 4000
    )
  end
end