defmodule Resp do
  def resp({:ok, %{"candidates" => [%{"content" => %{"parts" => parts}} | _]}}) do
    parts
  end

  def resp({:error, error}) do
    {:error, error}
  end

  def resp(_) do
    {:error, "parse failed"}
  end
end
