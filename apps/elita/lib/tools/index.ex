defmodule Tool.Index do
  import Kernel
  import Tools, only: [exec: 2]

  def set(key, value) do
    {result, _state} =
      exec(%{"name" => "set", "args" => %{"key" => "" <> key, "value" => value}}, %{})

    result
  end

  def get(key) do
    {result, _state} = exec(%{"name" => "get", "args" => %{"key" => "" <> key}}, %{})
    result
  end

  def tell(target, message) do
    {result, _state} = exec(tell_spec(target, message), %{})
    result
  end

  defp tell_spec(target, message) do
    %{"name" => "tell", "args" => %{"recipient" => "" <> target, "message" => "" <> message}}
  end
end
