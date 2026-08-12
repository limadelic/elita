defmodule DoorTest do
  use SpecHelper

  test "door opens into malko" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("CASSETTE_DIR")
      System.delete_env("TAPE")
    end)

    System.put_env("CASSETTE", "door")
    System.put_env("CASSETTE_DIR", cassette_dir)
    System.put_env("TAPE", "replay")

    frames = Matrix.Movie.Load.run(:malko)
    ansi = Matrix.Ansi.init(80, 24)

    rendered =
      Enum.reduce(frames, ansi, fn frame, state ->
        Matrix.Ansi.feed(state, frame)
      end)

    lines = Matrix.Ansi.lines(rendered)

    refute Enum.any?(lines, &(&1 =~ "\e"))
    refute Enum.any?(lines, &(&1 =~ "[38;5;"))

    welcome_line = Enum.find(lines, &(&1 =~ "Claude Code"))
    assert welcome_line, "Should render Claude Code on screen"
    assert welcome_line =~ ~r/[│╭╰]/
  end
end
