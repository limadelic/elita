defmodule Elita.Helpers do
  import Plug.Conn

  def reply({:ok, response}, conn) do
    json(conn, 200, response)
  end

  def reply({:error, reason}, conn) do
    json(conn, 400, %{error: reason})
  end

  def json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  def not_found(conn) do
    send_resp(conn, 404, "Not Found")
  end
end