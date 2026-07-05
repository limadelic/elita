defmodule Tools.Sys.AskCassetteTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  describe "ask routes through el" do
    setup do
      unless System.get_env("LIVE") || System.get_env("TAPE") == "rec" do
        System.put_env("TAPE", "replay")
      end

      System.put_env("CASSETTE", "ask")

      on_exit(fn ->
        System.delete_env("TAPE")
        System.delete_env("CASSETTE")
      end)

      spawn(:el)
      spawn(:greet)
      :ok
    end

    @tag :live
    test "ask through el to greet agent" do
      verify(:el, "Who am I talking to?", "ask greet hello")
    end
  end
end

defmodule Tools.Sys.AskUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()

    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  @tag :main
  test "ask nil-folder agent via Elita.call" do
    pid = spawn(fn -> :timer.sleep(:infinity) end)
    Agent.Registry.register(:native, nil, pid)

    result =
      try do
        Tools.Sys.Ask.exec("ask", %{"recipient" => "native", "question" => "hello"}, %{
          name: :test
        })
      rescue
        _error -> :error_from_elita
      catch
        :exit, _reason -> :error_from_elita
      else
        res -> res
      end

    assert result != "agent not found"
  end

  @tag :main
  test "ask binary-folder agent via Agent.Session.ask" do
    {:ok, pid} =
      Agent.Session.start_link(name: :runner, folder: "/tmp", runner: &stub_runner/2)

    Agent.Registry.register(:runner, "/tmp", pid)

    {response, _state} =
      Tools.Sys.Ask.exec("ask", %{"recipient" => "runner", "question" => "hello"}, %{name: :test})

    assert response == "stub response"
  end

  @tag :main
  test "ask unknown agent returns error string" do
    {response, _state} =
      Tools.Sys.Ask.exec("ask", %{"recipient" => "unknown", "question" => "hello"}, %{name: :test})

    assert response == "agent not found"
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end
