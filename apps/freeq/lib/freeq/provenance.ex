defmodule Freeq.Provenance do
  import Freeq.Keys, only: [cert: 1]
  import Freeq.Writer, only: [line: 2]
  import Base, only: [url_encode64: 2]

  def vouch(socket, name) do
    cert(name) |> present(socket)
  end

  defp present({:ok, body}, socket) do
    encoded = url_encode64(body, padding: false)
    line(socket, "PROVENANCE :" <> encoded)
    :ok
  end

  defp present({:error, _}, _socket) do
    :ok
  end
end
