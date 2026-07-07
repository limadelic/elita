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
    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  @tag :main
  test "ask native agent is registered in registry" do
    {:ok, _pid} = Elita.start_link(:native, [:native])

    assert [_ | _] = Registry.lookup(ElitaRegistry, "native")
  end

  @tag :main
  test "ask binary-folder agent via Agent.Session.ask" do
    {:ok, _pid} =
      Agent.Session.start_link(name: :runner, folder: "/tmp", runner: &stub_runner/2)

    {response, _state} =
      Tools.Sys.Ask.exec("ask", %{"recipient" => "runner", "question" => "hello"}, %{name: :test})

    assert response == "stub response"
  end

  @tag :main
  test "ask unknown agent returns error string" do
    {response, _state} =
      Tools.Sys.Ask.exec("ask", %{"recipient" => "unknown", "question" => "hello"}, %{name: :test})

    assert response == "unknown: unknown"
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end
