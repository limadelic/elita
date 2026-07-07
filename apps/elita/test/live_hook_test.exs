Code.require_file("tester.exs", __DIR__)

defmodule LiveHookTest do
  use Tester
  @moduletag :main

  @tag live: true
  test "live tag in context sets LIVE env var" do
    assert System.get_env("LIVE") == "1"
  end
end
