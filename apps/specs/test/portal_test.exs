defmodule PortalTest do
  use SpecHelper

  @tag :wip
  test "puppet answers through portal path" do
    stub_runner = fn _message, _folder, _self ->
      "response from stub"
    end

    {:ok, session_pid} =
      Agent.Session.start_link(
        name: "malko",
        folder: "/tmp",
        runner: stub_runner
      )

    Process.register(session_pid, :puppet)

    on_exit(fn ->
      try do
        Process.unregister(:puppet)
      catch
        :error, _ -> :ok
      end
    end)

    response = Agent.Portal.response("puppet", "1+1")
    verify("1 + 1 = **2**", response)
  end
end
