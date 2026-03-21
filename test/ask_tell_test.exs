defmodule AskTellTest do
  use ExUnit.Case

  test "ask missing recipient" do
    {msg, _} =
      Tools.Sys.Ask.exec(
        "ask",
        %{"recipient" => "missing_#{:rand.uniform(999_999_999)}", "question" => "hi"},
        %{name: "sender"}
      )

    assert msg =~ "not running"
  end

  test "tell missing recipient" do
    {msg, _} =
      Tools.Sys.Tell.exec(
        "tell",
        %{"recipient" => "missing_#{:rand.uniform(999_999_999)}", "message" => "hi"},
        %{name: "sender"}
      )

    assert msg =~ "not running"
  end
end
