defmodule LsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  defmodule FakeNetAdm do
    def names do
      [{:claude_elita, 1}, {:claude_scratch, 2}]
    end

    def names_empty do
      []
    end

    def names_error do
      {:error, :eacces}
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
        node: FakeNode,
        filter: fn {name, _port} ->
          Atom.to_string(name)
          |> String.starts_with?("claude_")
        end,
        extract: fn {name, _port} ->
          Atom.to_string(name)
          |> String.replace_prefix("claude_", "")
        end,
        ping: fn _name -> :pong end
      )
    end)

    assert String.contains?(output, "elita")
    assert String.contains?(output, "scratch")
  end

  test "prints no sessions when empty" do
    output = capture_io(fn ->
      El.Commands.Ls.execute(
        net_adm: __MODULE__.EmptyNetAdm,
        node: FakeNode,
        filter: fn {name, _port} ->
          Atom.to_string(name)
          |> String.starts_with?("claude_")
        end,
        extract: fn {name, _port} ->
          Atom.to_string(name)
          |> String.replace_prefix("claude_", "")
        end,
        ping: fn _name -> :pong end
      )
    end)

    assert String.contains?(output, "no sessions")
  end

  defmodule EmptyNetAdm do
    def names do
      []
    end
  end
end
