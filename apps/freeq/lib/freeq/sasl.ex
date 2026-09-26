defmodule Freeq.SASL do
  import String, only: [trim_trailing: 2, split: 1, contains?: 2]
  import Base, only: [url_encode64: 2, url_decode64!: 2]
  import Enum, only: [reverse: 1, at: 3]
  import Freeq.Did, only: [key: 1, sign: 2, did: 1]
  import Freeq.Keys, only: [seed: 1]
  import Freeq.Writer, only: [line: 2]
  import Jason, only: [encode!: 1]

  def login(socket, name) do
    line(socket, "AUTHENTICATE ATPROTO-CHALLENGE")
    socket |> await("AUTHENTICATE ") |> respond(socket, name)
  end

  defp respond({:ok, text}, socket, name) do
    chal = decode(text)
    prove(socket, chal, name)
    socket |> await(" 903 ") |> finish(socket)
  end

  defp respond(error, _socket, _name), do: error

  defp finish({:ok, _}, socket) do
    line(socket, "CAP END")
    :ok
  end

  defp finish(error, _socket), do: error

  defp decode(text) do
    [chal | _] = text |> split() |> reverse()
    url_decode64!(chal, padding: false)
  end

  defp prove(socket, chal, name) do
    {pub, priv} = name |> seed() |> elem(1) |> key()
    sig64 = url_encode64(sign(chal, priv), padding: false)
    json = encode!(%{did: did(pub), signature: sig64})
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
