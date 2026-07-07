defmodule Tools.Sys.TellUnitTest do
  use ExUnit.Case

  setup do
    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  test "tell nil-folder agent via Elita.cast" do
    {:ok, _pid} = Elita.start_link(:native, [:native])

    result =
      try do
        Tools.Sys.Tell.exec("tell", %{"recipient" => "native", "message" => "hello"}, %{
          name: :test
        })
      rescue
        _error -> :error_from_elita
      catch
        :exit, _reason -> :error_from_elita
      else
        res -> res
      end

    {response, _state} = result
    assert response == "sent"
  end

  test "tell binary-folder agent via Agent.Session.cast" do
    {:ok, _pid} =
      Agent.Session.start_link(name: :runner, folder: "/tmp", runner: &stub_runner/2)

    {response, _state} =
      Tools.Sys.Tell.exec("tell", %{"recipient" => "runner", "message" => "hello"}, %{name: :test})

    assert response == "sent"
  end

  test "tell unknown agent still returns sent" do
    {response, _state} =
      Tools.Sys.Tell.exec("tell", %{"recipient" => "unknown", "message" => "hello"}, %{
        name: :test
      })

    assert response == "sent"
  end

  test "tell with empty args returns error message" do
    state = %{name: :test}

    {result, ^state} = Tools.Sys.Tell.exec("tell", %{}, state)

    assert is_binary(result)
    assert String.contains?(result, "tell")
    assert String.contains?(result, "needs")
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end
