defmodule Freeq.Did do
  import Integer, only: [digits: 2]
  import Enum, only: [map: 2, at: 2]
  import :binary, only: [decode_unsigned: 1]

  @b58 ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  def key, do: :crypto.generate_key(:eddsa, :ed25519)

  def key(seed), do: :crypto.generate_key(:eddsa, :ed25519, seed)

  def sign(bytes, priv) do
    :crypto.sign(:eddsa, :none, bytes, [priv, :ed25519])
  end

  def did(pub), do: "did:key:z" <> b58(<<0xED, 0x01>> <> pub)

  defp b58(bin) do
    bin |> decode_unsigned() |> digits(58) |> map(&at(@b58, &1)) |> to_string()
  end
end
