defmodule Resp do
  def resp({:ok, %{"candidates" => [%{"content" => %{"parts" => parts}} | _]}}) do
    parse(parts)
  end

  def resp({:error, error}) do
    {:error, error}
  end

  def resp(_) do
    {:error, "parse failed"}
  end

  defp parse(parts) do
    case call(parts) do
      nil -> {:text, text(parts)}
      call -> {:function_call, call}
    end
  end

  defp call([%{"functionCall" => call} | _]), do: call
  defp call([_ | rest]), do: call(rest)
  defp call([]), do: nil

  defp text([%{"text" => text} | _]), do: text
  defp text([_ | rest]), do: text(rest)
  defp text([]), do: ""
end