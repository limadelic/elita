defmodule Tester do
  import ExUnit.Assertions
  import Elita, only: [start_link: 2, cast: 2, call: 2]

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

    assert String.contains?(String.downcase(answer), String.downcase("#{expected}")),
           "Expected '#{answer}' to contain '#{expected}'"
  end

  def wait_until(agent, cond) do
    verify(agent, "yes", "did you #{cond}?")
  rescue
    _ -> wait_until(agent, cond)
  end

  def speck(name) do
    spawn(name, :speck)
    verify(name, "passed", "test #{name}")
  end
end
