defmodule Resp do
  import Jason, only: [decode: 1]
  
  alias HTTPoison.Response, as: Ok
  alias HTTPoison.Error

  def resp({:ok, %Ok{status_code: 200, body: body}}) do
    resp(decode(body))
  end

  def resp({:ok, %Ok{status_code: code}}) do
    {:error, "HTTP #{code}"}
  end

  def resp({:error, %Error{reason: reason}}) do
    {:error, "#{reason}"}
  end

  def resp({:ok, %{"candidates" => [%{"content" => %{"parts" => parts}} | _]}}) do
    parts
  end

  def resp({:error, error}) do
    {:error, error}
  end

  def resp(response) do
    IO.inspect(response, label: "RESPONSE")
    {:error, "parse failed"}
  end
end
