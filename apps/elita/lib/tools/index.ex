defmodule Tool.Index do
  import Tools, only: [exec: 2]

  def set(key, value) do
    {result, _state} = exec(spec(:set, key, value), %{})
    result
  end

  defp spec(op, key, value) do
    %{"name" => "#{op}", "args" => %{"key" => "#{key}", "value" => value}}
  end

  def get(key) do
    {result, _state} =
      exec(%{"name" => "get", "args" => %{"key" => "#{key}"}}, %{})

    result
  end

  def tell(target, message) do
    {result, _state} = exec(task(target, message), %{})
    result
  end

  defp task(target, message) do
    %{
      "name" => "tell",
      "args" => %{"recipient" => "#{target}", "message" => "#{message}"}
    }
  end
end
