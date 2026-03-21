defmodule MindTest do
  use Tester

  test "mind solves simple problem directly" do
    spawn(:mind)

    verify(:mind, "4", "what is 2 + 2?")
  end

  test "mind defines and spawns agents for complex task" do
    spawn(:mind)

    ask(:mind, "I need a greeting in three languages: spanish, french, and japanese. Define a specialist agent for each language, spawn them, ask each for a greeting, and combine the results.")

    wait_until(:mind, "provide greetings in all three languages")
  end

  test "mind decomposes research task" do
    spawn(:mind)

    ask(:mind, "Compare the pros and cons of Python vs Elixir for building concurrent systems. Define one agent to argue for Python and another to argue for Elixir, then synthesize their arguments.")

    wait_until(:mind, "provide a comparison of both languages")
  end
end
