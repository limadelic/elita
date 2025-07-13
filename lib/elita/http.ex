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
  import Elita.Helpers

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/agents/:name" do
    Elita.Agent.decide(name, conn.body_params)
    |> respond(conn)
  end

  match _ do
    not_found(conn)
  end
end