defmodule Freeq.SASL do
  import String, only: [trim_trailing: 2, split: 1, contains?: 2]
  import Base, only: [url_encode64: 2, url_decode64!: 2]
  import Enum, only: [reverse: 1]
  import Freeq.Did, only: [key: 1, sign: 2, did: 1]
  import Freeq.Keys, only: [seed: 1]
  import Freeq.Writer, only: [line: 2]
  import Jason, only: [encode!: 1]

  def login(socket, name) do
    {pub, priv} = name |> seed() |> elem(1) |> key()
    line(socket, "AUTHENTICATE ATPROTO-CHALLENGE")
    respond(socket, did(pub), sign(challenge(socket), priv))
    auth(socket)
  end

  defp auth(socket) do
    await(socket, " 903 ")
    line(socket, "CAP END")
  end

  defp challenge(socket) do
    [chal | _] = await(socket, "AUTHENTICATE ") |> split() |> reverse()
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
        pick(contains?(text, mark), text, socket, mark)
      {:tcp_closed, ^socket} -> raise "Socket closed waiting for #{mark}"
    after
      5000 -> raise "Timeout waiting for #{mark}"
    end
  end

  defp pick(true, text, _socket, _mark), do: text
  defp pick(false, _text, socket, mark), do: await(socket, mark)
end
