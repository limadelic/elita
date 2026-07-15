defmodule Tester do
  import ExUnit.Assertions
  import Elita, only: [request: 2, dispatch: 2]
  import String, only: [downcase: 1]
  import Log, only: [log: 5]

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import Tester

      setup_all do
        {:ok, _} = Tape.Writer.start_link(nil)
        :ok
      end
    end
  end

  def spawn(name) do
    spawn(name, [name])
  end

  def spawn(name, configs) do
    Elita.spawn(to_string(name), to_configs(configs))
  end

  defp to_configs(configs) when is_list(configs) do
    configs |> Enum.map(&to_string/1)
  end

  defp to_configs(config) do
    [to_string(config)]
  end

  def tell(name, msg) do
    log("📢", "user → #{name}", ": ", msg, :yellow)
    dispatch(to_string(name), msg)
  end

  def ask(name, query) do
    log("🤔", "user → #{name}", ": ", query, :green)
    request(to_string(name), query)
  end

  def judge(result, expectation) do
    prompt = "Result: #{result}\n\nExpectation: #{expectation}"
    verdict = ask(:judge, prompt)

    assert is_binary(verdict), "Expected binary verdict, got: #{inspect(verdict)}"
    assert downcase(verdict) == "yes",
           "Judge said: #{verdict}. Expectation failed: #{expectation}"
  end
end
