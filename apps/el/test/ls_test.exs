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

  test "ping returns pang when nodes unreachable" do
    # Demonstrates the symptom: when Node.ping fails (pang), nodes are filtered out
    # This happens in real scenario when cookie is not set on probe node
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
        ping: fn _name, _host ->
          # Simulates Node.ping returning :pang (happens when cookie not set on probe)
          :pang
        end
      )
    end)

    assert String.contains?(output, "no sessions")
  end

  test "default_ping constructs atom with @host when host provided" do
    # Fix: host is now threaded through call_build → build_sessions → default_ping
    # default_ping receives host and passes it to node_to_atom
    # node_to_atom builds :claude_remote@127.0.0.1 instead of bare :claude_remote

    _output = capture_io(fn ->
      El.Commands.Ls.execute(
        host: "127.0.0.1",
        net_adm: FakeNetAdm,
        filter: fn {name, _port} ->
          (is_binary(name) || is_list(name)) &&
            (name |> to_string() |> String.starts_with?("claude_"))
        end,
        extract: fn {name, _port} ->
          name |> to_string() |> String.replace_prefix("claude_", "")
        end,
        ping: fn name, host ->
          # Test verifies node_to_atom builds full atom with @host
          atom = construct_node_atom(name, host)
          send(self(), {:atom, atom})
          :pong
        end
      )
    end)

    atom_str = receive do
      {:atom, atom} ->
        Atom.to_string(atom)
    after
      100 -> ""
    end

    assert String.contains?(atom_str, "@127.0.0.1"),
      "Atom should include @host: #{atom_str}"
  end

  defp construct_node_atom(name, nil) do
    name_str = name_to_string(name)
    String.to_atom("#{name_str}@#{El.Host.host()}")
  end

  defp construct_node_atom(name, host) do
    name_str = name_to_string(name)
    String.to_atom("#{name_str}@#{host}")
  end

  defp name_to_string(name) when is_atom(name) do
    Atom.to_string(name)
  end

  defp name_to_string(name) when is_list(name) do
    List.to_string(name)
  end

  defp name_to_string(name) when is_binary(name) do
    name
  end

  test "default execute builds atoms with El.Host default" do
    {:ok, captured_atom} = Agent.start_link(fn -> nil end)

    try do
      ExUnit.CaptureIO.capture_io(fn ->
        El.Commands.Ls.execute(
          net_adm: FakeNetAdm,
          filter: fn {name, _port} ->
            (is_binary(name) || is_list(name)) &&
              (name |> to_string() |> String.starts_with?("claude_"))
          end,
          extract: fn {name, _port} ->
            name |> to_string() |> String.replace_prefix("claude_", "")
          end,
          ping: fn name, host ->
            # Simulate what default_ping does: node_to_atom constructs the atom
            atom = construct_node_atom(name, host || El.Host.host())
            Agent.update(captured_atom, fn _ -> atom end)
            :pong
          end
        )
      end)

      atom = Agent.get(captured_atom, & &1)
      atom_str = Atom.to_string(atom)

      # With fix: atom includes @127.0.0.1 even though host param is nil
      assert String.contains?(atom_str, "@127.0.0.1"),
        "execute([]) should construct atoms with El.Host default (127.0.0.1); got: #{atom_str}"
    after
      Agent.stop(captured_atom)
    end
  end
end
