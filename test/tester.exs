defmodule Tester do
  import ExUnit.Assertions
  import Elita, only: [start_link: 2, cast: 2, call: 2]
  import Lite, only: [llm: 1]
  import String, only: [contains?: 2, downcase: 1]
  import Enum, only: [map: 2]
  import GenServer, only: [stop: 1]
  import Log, only: [log: 5]
  import File, only: [read!: 1]

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import Tester
    end
  end

  def spawn(name) do
    setup()
    start_link(name(name), list([name(name)]))
  end

  def spawn(name, configs) do
    setup()
    start_link(name(name), list(configs) |> map(&to_string/1))
  end

  defp list(configs) when is_list(configs), do: configs
  defp list(config), do: [config]

  def halt(name) do
    stop(via(name))
  rescue
    _ -> :ok
  end

  defp via(name) do
    {:via, Registry, {ElitaRegistry, name}}
  end

  defp setup do
    :ok
  end

  defp name(n), do: to_string(n)

  def tell(name, msg) do
    log("📢", "user → #{name}", ": ", msg, :yellow)
    cast(name(name), msg)
  end

  def ask(name, query) do
    log("🤔", "user → #{name}", ": ", query, :green)
    call(name(name), query)
  end

  def verify(name, expected, query) do
    answer = ask(name, query)

    try do
      assert contains?(downcase(answer), downcase("#{expected}")),
             "Expected '#{answer}' to contain '#{expected}'"
    rescue
      ExUnit.AssertionError ->
        ask_llm(answer, expected, query)
    end
  end

  defp ask_llm(answer, expected, query) do
    prompt = "Does the response '#{answer}' match the expected behavior '#{expected}' when asked '#{query}'? Answer only yes or no."
    result = llm(prompt)

    assert contains?(downcase(result), "yes"),
           "LLM judge failed: Expected '#{answer}' to match '#{expected}' for query '#{query}'"
  end

  def wait_until(agent, cond, retries \\ 5)
  def wait_until(_agent, cond, 0), do: raise "Timeout waiting for: #{cond}"
  def wait_until(agent, cond, retries) do
    verify(agent, "yes", "did you #{cond}?")
  rescue
    _ -> wait_until(agent, cond, retries - 1)
  end

  def speck(name) do
    spawn(name, :speck)
    verify(name, "passed", "exec #{name}")
  end

  def silkd(name) do
    spawn(name, :silkd)
    silk = read!("test/silk/#{name}.md")
    verify(name, silk, "weave #{name}")
  end
end
