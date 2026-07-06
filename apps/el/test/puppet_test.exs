Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule PuppetTest do
  use Tester
  @moduletag :live

  describe "puppet session" do
    setup do
      System.put_env("AGENT_REGISTRATIONS", "puppet:/Users/mike/dude")

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
      boot_puppet()
      :ok
    end

    defp boot_puppet do
      Agent.Config.load()
      |> Enum.each(&start_puppet_session/1)
    end

    defp start_puppet_session({:puppet, _folder}) do
      # Boot el claude as a puppet session
      # TODO: Implement puppet session startup
      :ok
    end

    defp start_puppet_session(_), do: :ok

    @tag timeout: 300_000
    test "el routes ask to puppet session" do
      verify(:el, "2", "ask puppet 1 + 1")
    end
  end
end
