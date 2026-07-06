Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule PuppetTest do
  use Tester
  @moduletag :live

  describe "calculator session" do
    setup do
      System.put_env("AGENT_REGISTRATIONS", "calculator:/Users/mike/dude")

      on_exit(fn ->
        try do
          halt(:el)
        rescue
          _ -> :ok
        catch
          :exit, _ -> :ok
        end
        System.delete_env("AGENT_REGISTRATIONS")
      end)

      spawn(:el)
      boot_calculator()
      :ok
    end

    defp boot_calculator do
      Agent.Config.load()
      |> Enum.each(&start_calculator_session/1)
    end

    defp start_calculator_session({:calculator, _folder}) do
      # Boot el claude as a calculator session
      # TODO: Implement calculator session startup
      :ok
    end

    defp start_calculator_session(_), do: :ok

    @tag timeout: 300_000
    test "el routes ask to calculator session" do
      verify(:el, "2", "ask calculator 1 + 1")
    end
  end
end
