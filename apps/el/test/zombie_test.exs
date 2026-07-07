Code.require_file("../../elita/test/tester.exs", __DIR__)

defmodule ZombieTest do
  use Tester
  @moduletag :live

  describe "zombie routing" do
    setup do
      System.put_env("AGENT_REGISTRATIONS", "dude:/Users/mike/dude")

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

    test "el routes ask to dude session" do
      verify(:el, "dude", "ask dude what is your name")
    end
  end
end
