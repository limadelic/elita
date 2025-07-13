defmodule Elita.Router do
  use Plug.Router
  alias Elita.{Agent, Helpers}
  import Helpers

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/agents/:name" do
    Agent.decide(name, conn.body_params)
    |> respond(conn)
  end

  match _ do
    not_found(conn)
  end
end