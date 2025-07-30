defmodule Resp do
  def parse({:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}}) do
    {:text, text}
  end

  def parse({:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"functionCall" => function_call}]}} | _]}}) do
    {:function_call, function_call}
  end

  def parse(_) do
    {:error, "parse failed"}
  end
end