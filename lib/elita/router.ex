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