defmodule Resp do
  def resp({:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}}) do
    {:text, text}
  end

  def resp({:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"functionCall" => function_call}]}} | _]}}) do
    {:function_call, function_call}
  end

  def resp(response) do
    IO.inspect(response, label: "FAILED TO PARSE")
    {:error, "parse failed"}
  end
end