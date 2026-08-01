defmodule SpecHelper do
  import ExUnit.Assertions
  import ExUnit.Callbacks

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import SpecHelper

      setup_all do
        case Tape.Writer.start_link(nil) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

        System.put_env("CASSETTE_DIR", Path.expand("../../../features/cassettes", __DIR__))

        :ok
      end

      setup context do
        cassette = context[:cassette] || default_cassette()
        System.put_env("CASSETTE", cassette)
        System.put_env("TAPE", "replay")
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
    reset()
    El.Distribution.start("specs")
    opts = tape_opts()
    Elita.spawn(to_string(name), to_configs(configs), opts)
    on_exit(fn -> kill(name) end)
  end

  defp tape_opts do
    [
      tape_env: %{
        tape: System.get_env("TAPE"),
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

  defp reset do
    Tape.Writer.acquire(fn -> :ok end)
  end

  def ask(name, query) do
    output = capture(fn -> El.Commands.Ask.ask(to_string(name), query) end)
    clean(output)
  end

  def tell(name, msg) do
    El.Commands.Address.Send.tell(to_string(name), msg, nil)
  end

  defp capture(fun) do
    ExUnit.CaptureIO.capture_io(fun)
  end

  defp clean(output) do
    output
    |> String.replace(~r/\e\[[^a-zA-Z]*[a-zA-Z]/, "")
    |> String.replace(~r/\e\][^\e]*(?:\e\\|\x07)/, "")
    |> String.trim()
  end

  def verify(expectation, result) do
    pattern = ~r/#{Regex.escape(expectation)}/i

    assert result =~ pattern,
           "Expected substring '#{expectation}' in result: #{result}"
  end
end
