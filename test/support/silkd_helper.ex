defmodule SilkdHelper do
  import ExUnit.Callbacks, only: [start_supervised!: 1]

  def start do
    pid = start_supervised!({Silkd, transport: {:stdio, command: "npx", args: ["@playwright/mcp"]}})
    Process.sleep(2000)
    pid
  end

  def stop(_pid) do
    :ok
  end

  def navigate(url) do
    {:ok, result} = Silkd.navigate(url)
    [%{"text" => text}] = result.result["content"]
    text
  end

  def content do
    {:ok, result} = Silkd.content()
    [%{"text" => text}] = result.result["content"]
    text
  end
end
