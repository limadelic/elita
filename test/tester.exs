defmodule Tester do
  import ExUnit.Assertions
  import Elita, only: [start_link: 2, cast: 2, call: 2]
  import Llm, only: [llm: 1]
  import String, only: [contains?: 2, downcase: 1]

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
    start_link(name(name), list(configs) |> Enum.map(&to_string/1))
  end

  defp list(configs) when is_list(configs), do: configs
  defp list(config), do: [config]

  def stop(name) do
    GenServer.stop(via(name))
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
    Log.log("📢", "user → #{name}", ": ", msg, :yellow)
    cast(name(name), msg)
  end

  def ask(name, query) do
    Log.log("🤔", "user → #{name}", ": ", query, :green)
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
    prompt = %{
      contents: [
        %{
          role: "user",
          parts: [
            %{
              text:
                "Does the response '#{answer}' match the expected behavior '#{expected}' when asked '#{query}'? Answer only yes or no."
            }
          ]
        }
      ]
    }

    [%{"text" => result}] = llm(prompt)

    assert contains?(downcase(result), "yes"),
           "LLM judge failed: Expected '#{answer}' to match '#{expected}' for query '#{query}'"
  end

  def wait_until(agent, cond) do
    verify(agent, "yes", "did you #{cond}?")
  rescue
    _ -> wait_until(agent, cond)
  end

  def speck(name) do
    spawn(name, :speck)
    verify(name, "passed", "exec #{name}")
  end
end
