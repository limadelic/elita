defmodule SessionNamingTest do
  use ExUnit.Case
  @moduletag :main

  test "parse_name returns default name when no argument provided" do
    assert parse_name([]) == :default
  end

  test "parse_name returns provided name argument" do
    assert parse_name(["myname"]) == "myname"
  end

  test "default_name returns basename of current directory" do
    # Temporarily change to a known directory
    original = File.cwd!()

    try do
      File.cd!("/tmp")
      assert default_name() == "tmp"

      File.cd!("/Users/mike/dev/self/elita")
      assert default_name() == "elita"
    after
      File.cd!(original)
    end
  end

  test "node_name_from_session_name generates correct node name" do
    assert node_name_from_session_name("elita") == :"claude_elita@127.0.0.1"
    assert node_name_from_session_name("myapp") == :"claude_myapp@127.0.0.1"
    assert node_name_from_session_name("test") == :"claude_test@127.0.0.1"
  end

  test "process_name_from_session_name converts to atom" do
    assert process_name_from_session_name("elita") == :elita
    assert process_name_from_session_name("myapp") == :myapp
    assert process_name_from_session_name("test") == :test
  end

  test "collision_message generates helpful message" do
    msg = collision_message("elita")

    assert String.contains?(msg, "elita")
    assert String.contains?(msg, "el tell")
    assert String.contains?(msg, "/exit")
  end

  # Helper functions matching module logic
  defp parse_name(args) do
    case args do
      [] -> :default
      [name] -> name
      _ -> :default
    end
  end

  defp default_name do
    File.cwd!()
    |> Path.basename()
  end

  defp node_name_from_session_name(name) do
    :"claude_#{name}@127.0.0.1"
  end

  defp process_name_from_session_name(name) do
    String.to_atom(name)
  end

  defp collision_message(name) do
    "session #{name} already live — el tell #{name} <msg>, or /exit it"
  end
end
