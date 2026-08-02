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

        regs = registrations()
        Application.put_env(:elita, :registrations, regs)

        System.delete_env("LIVE")
        System.delete_env("TAPE_ON_MISS")
        System.delete_env("ANTHROPIC_API_KEY")

        :ok
      end

      setup context do
        cassette = context[:cassette] || default_cassette()
        System.put_env("CASSETTE", cassette)
        System.put_env("TAPE", "replay")

        if clock_override = context[:clock_override] do
          Application.put_env(:elita, :clock_override, clock_override)
          on_exit(fn -> Application.delete_env(:elita, :clock_override) end)
        end

        :ok
      end

      defp registrations do
        base = Path.expand("../../../agents", __DIR__)

        [
          "elita:#{Path.join(base, "elita")}",
          "games:#{Path.join(base, "games")}",
          "speck:#{Path.join(base, "speck")}",
          "tools:#{Path.join(base, "tools")}"
        ]
        |> Enum.join(",")
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
    spawn(name, name)
  end

  def spawn(name, config) when not is_list(config) do
    spawn(name, [config])
  end

  def spawn(name, [single_config]) do
    kill(name)
    reset()
    capture(fn -> El.CLI.main(["spawn", to_string(name), to_string(single_config)]) end)
    on_exit(fn -> kill(name) end)
  end

  def spawn(name, configs) when is_list(configs) and length(configs) > 1 do
    kill(name)
    reset()
    El.Distribution.start("specs")
    opts = tape_opts()
    Elita.spawn(to_string(name), Enum.map(configs, &to_string/1), opts)
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

  defp kill(name) do
    normalized = name |> to_string() |> String.downcase()

    case Registry.lookup(ElitaRegistry, normalized) do
      [] -> :ok
      [{pid, _} | _] -> GenServer.stop(pid)
    end
  end

  defp reset do
    Tape.Writer.acquire(fn -> :ok end)
  end

  def ask(name, query) do
    output = capture(fn -> El.CLI.main(["ask", to_string(name), query]) end)
    clean(output)
  end

  def tell(name, msg) do
    capture(fn -> El.CLI.main(["tell", to_string(name), msg]) end)
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
