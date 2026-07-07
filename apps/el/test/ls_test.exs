defmodule LsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  defmodule FakeNetAdm do
    def names do
      {:ok, [{~c"claude_elita", 1}, {~c"claude_scratch", 2}]}
    end

    def names(_host) do
      {:ok, [{~c"claude_remote", 3}]}
    end

    def names_empty do
      {:ok, []}
    end

    def names_error do
      {:error, :eacces}
    end
  end

  defmodule FakeNetAdmAtoms do
    def names do
      [{:claude_elita, 1}, {:claude_scratch, 2}]
    end
  end

  defmodule FakeNode do
    def ping(:alive) do
      :pong
    end

    def ping(:dead) do
      :pang
    end
  end

  test "lists session names from live nodes" do
    output = capture_io(fn ->
      El.Commands.Ls.execute(
        net_adm: FakeNetAdm,
        filter: fn {name, _port} ->
          (is_binary(name) || is_list(name)) &&
            (name |> to_string() |> String.starts_with?("claude_"))
        end,
        extract: fn {name, _port} ->
          name |> to_string() |> String.replace_prefix("claude_", "")
        end,
        ping: fn _name, _host -> :pong end
      )
    end)

    assert String.contains?(output, "elita")
    assert String.contains?(output, "scratch")
  end

  test "prints no sessions when empty" do
    output = capture_io(fn ->
      El.Commands.Ls.execute(
        net_adm: __MODULE__.EmptyNetAdm,
        filter: fn {name, _port} ->
          (is_binary(name) || is_list(name)) &&
            (name |> to_string() |> String.starts_with?("claude_"))
        end,
        extract: fn {name, _port} ->
          name |> to_string() |> String.replace_prefix("claude_", "")
        end,
        ping: fn _name, _host -> :pong end
      )
    end)

    assert String.contains?(output, "no sessions")
  end

  test "lists remote sessions when host provided" do
    output = capture_io(fn ->
      El.Commands.Ls.execute(
        host: "home.local",
        net_adm: FakeNetAdm,
        filter: fn {name, _port} ->
          (is_binary(name) || is_list(name)) &&
            (name |> to_string() |> String.starts_with?("claude_"))
        end,
        extract: fn {name, _port} ->
          name |> to_string() |> String.replace_prefix("claude_", "")
        end,
        ping: fn _name, _host -> :pong end
      )
    end)

    assert String.contains?(output, "remote")
  end

  defmodule EmptyNetAdm do
    def names do
      []
    end

    def names(_host) do
      []
    end
  end
end
