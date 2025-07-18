defmodule Api.AgentController do
  use Phoenix.Controller

  def act(conn, %{"name" => name} = params) do
    case Elita.Agent.act(name, params) do
      {:ok, response} -> json(conn, response)
      {:error, reason} -> conn |> put_status(500) |> json(%{error: reason})
    end
  end

  def state(conn, %{"name" => name}) do
    case Registry.lookup(Elita.AgentRegistry, name) do
      [{pid, _}] -> json(conn, %{name: name, pid: inspect(pid), status: "alive"})
      [] -> conn |> put_status(404) |> json(%{error: "agent not found"})
    end
  end

  def stream(conn, %{"name" => name}) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_chunked(200)
    |> stream_agent_updates(name)
  end

  defp stream_agent_updates(conn, name) do
    Phoenix.PubSub.subscribe(Elita.PubSub, name)
    
    receive do
      {:intercom, from, message} ->
        data = Jason.encode!(%{from: from, message: message, timestamp: System.system_time(:millisecond)})
        case chunk(conn, "data: #{data}\n\n") do
          {:ok, conn} -> stream_agent_updates(conn, name)
          {:error, _} -> conn
        end
    after
      30_000 -> conn
    end
  end
end