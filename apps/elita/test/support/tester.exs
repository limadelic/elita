defmodule Tester do
  import ExUnit.Assertions
  import Elita, only: [request: 2, dispatch: 2]

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import Tester

      setup_all do
        {:ok, _} = Tape.Writer.start_link(nil)

        cassette =
          __MODULE__
          |> Module.split()
          |> List.last()
          |> String.replace_suffix("Test", "")
          |> String.downcase()

        System.put_env("CASSETTE", cassette)

        on_exit(fn ->
          System.delete_env("CASSETTE")
        end)

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
    dispatch(to_string(name), msg)
  end

  def ask(name, query) do
    request(to_string(name), query)
  end

  def verify(expectation, result) do
    pattern = ~r/#{Regex.escape(expectation)}/i

    assert result =~ pattern,
           "Expected substring '#{expectation}' in result: #{result}"
  end
end
