defmodule Tester do
  import ExUnit.Assertions
  import ExUnit.Callbacks
  import Elita, only: [request: 2, dispatch: 2]

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import Tester

      setup_all do
        case Tape.Writer.start_link(nil) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

        System.put_env("CASSETTE_DIR", Path.expand("../../../../features/cassettes", __DIR__))

        :ok
      end

      setup context do
        cassette = context[:cassette] || default_cassette()
        System.put_env("CASSETTE", cassette)
        :ok
      end

      defp default_cassette do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> String.replace_suffix("Test", "")
        |> String.downcase()
      end
    end
  end

  def spawn(name) do
    spawn(name, [name])
  end

  def spawn(name, configs) do
    kill(name)
    reset_tape_writer()
    opts = tape_opts()
    Elita.spawn(to_string(name), to_configs(configs), opts)
    on_exit(fn -> kill(name) end)
  end

  defp tape_opts do
    [
      tape_env: %{
        tape: System.get_env("TAPE"),
        live: System.get_env("LIVE"),
        cassette: System.get_env("CASSETTE"),
        cassette_dir: System.get_env("CASSETTE_DIR")
      }
    ]
  end

  defp to_configs(configs) when is_list(configs) do
    configs |> Enum.map(&to_string/1)
  end

  defp to_configs(config) do
    [to_string(config)]
  end

  defp kill(name) do
    normalized = name |> to_string() |> String.downcase()

    {:via, Registry, {ElitaRegistry, normalized, %{kind: :native, folder: nil}}}
    |> GenServer.whereis()
    |> case do
      nil -> :ok
      pid -> GenServer.stop(pid)
    end
  end

  defp reset_tape_writer do
    Tape.Writer.acquire(fn -> :ok end)
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

  def await(fun) do
    await_loop(fun, 120_000, 500)
  end

  defp await_loop(_fun, remaining, _interval) when remaining <= 0 do
    {:error, "timeout"}
  end

  defp await_loop(fun, remaining, interval) do
    case fun.() do
      true ->
        :ok

      false ->
        Process.sleep(interval)
        await_loop(fun, remaining - interval, interval)
    end
  end
end
