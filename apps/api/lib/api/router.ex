defmodule Api.Router do
  use Plug.Router
  alias Elita.{Agent, Helpers}
  import Helpers, only: [reply: 2, not_found: 1]

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/agents/:name" do
    name
    |> Agent.act(conn.body_params)
    |> reply(conn)
  end

  match _ do
    not_found(conn)
  end

  def child_spec(_) do
    Bandit.child_spec(
      plug: __MODULE__,
      scheme: :http,
      port: 4000
    )
  end
end