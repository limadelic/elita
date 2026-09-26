defmodule Freeq.SASL do
  import String, only: [trim_trailing: 2, split: 1, contains?: 2]
  import Base, only: [url_encode64: 2, url_decode64!: 2]
  import Enum, only: [reverse: 1, at: 3]
  import Freeq.Did, only: [key: 1, sign: 2, did: 1]
  import Freeq.Keys, only: [seed: 1]
  import Freeq.Writer, only: [line: 2]
  import Jason, only: [encode!: 1]

  def login(socket, name) do
    {pub, priv} = name |> seed() |> elem(1) |> key()
    line(socket, "AUTHENTICATE ATPROTO-CHALLENGE")
    respond(socket, did(pub), sign(challenge(socket), priv))
    await(socket, " 903 ") |> done(socket)
  end

  defp done({:ok, _text}, socket) do
    line(socket, "CAP END")
    :ok
  end

  defp done({:error, _} = e, _socket) do
    e
  end

  defp challenge(socket) do
    {:ok, text} = await(socket, "AUTHENTICATE ")
    [chal | _] = text |> split() |> reverse()
    url_decode64!(chal, padding: false)
  end

  defp respond(socket, did, sig) do
    sig64 = url_encode64(sig, padding: false)
    json = encode!(%{did: did, signature: sig64})
    line(socket, "AUTHENTICATE #{url_encode64(json, padding: false)}")
  end

  defp await(socket, mark) do
    receive do
      {:tcp, ^socket, data} ->
        text = data |> to_string() |> trim_trailing("\r\n")
        status(contains?(text, " 433 "), contains?(text, mark))
        |> pick(socket, text, mark)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for #{mark}"
    after
      5000 -> raise "Timeout waiting for #{mark}"
    end
  end

  defp status(true, _), do: :nick_taken
  defp status(false, true), do: :ok
  defp status(false, false), do: :continue

  defp pick(:ok, _socket, text, _mark), do: {:ok, text}
  defp pick(:nick_taken, _socket, text, _mark) do
    {:error, "nick #{at(split(text), 3, "unknown")} in use"}
  end
  defp pick(:continue, socket, _text, mark), do: await(socket, mark)
end
