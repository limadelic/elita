defmodule DudeUnitTest do
  use Tester
  @moduletag :dude
  @moduletag :spec

  describe "routing messages" do
    setup do
      unless System.get_env("LIVE") || System.get_env("TAPE") == "rec" do
        System.put_env("TAPE", "replay")
      end

      System.put_env("CASSETTE", "dude")
      System.put_env("AGENT_REGISTRATIONS", "dude:/Users/mike/dude")

      on_exit(fn ->
        System.delete_env("TAPE")
        System.delete_env("CASSETTE")
        System.delete_env("AGENT_REGISTRATIONS")
      end)

      spawn(:el)
      boot_dude()
      :ok
    end

    defp boot_dude do
      Agent.Config.load()
      |> Enum.each(&start_dude_session/1)
    end

    defp start_dude_session({:dude, folder}) do
      {:ok, pid} = Agent.Session.start_link(name: :dude, folder: folder)
      Agent.Registry.register(:dude, folder, pid)
    end

    defp start_dude_session(_), do: :ok

    @tag :live
    test "el routes ask message to dude agent via registered session" do
      verify(:el, "dude", "ask dude what is your name")
    end
  end
end
