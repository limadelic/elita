defmodule El.Pty.DsrTest do
  use ExUnit.Case

  alias El.Pty.Dsr

  describe "scan" do
    test "detects DSR query and returns CPR response" do
      {response, remaining} = Dsr.scan("\e[6n", 24, 80)
      assert response == "\e[24;80R"
      assert remaining == ""
    end

    test "handles DSR with data before and after" do
      {response, remaining} = Dsr.scan("hello\e[6nworld", 24, 80)
      assert response == "\e[24;80R"
      assert remaining == "helloworld"
    end

    test "handles primary DA query" do
      {response, remaining} = Dsr.scan("\e[c", 24, 80)
      assert response == "\e[?6c"
      assert remaining == ""
    end

    test "handles DA with surrounding data" do
      {response, remaining} = Dsr.scan("x\e[cy", 24, 80)
      assert response == "\e[?6c"
      assert remaining == "xy"
    end

    test "no query returns empty response" do
      {response, remaining} = Dsr.scan("hello", 24, 80)
      assert response == ""
      assert remaining == "hello"
    end

    test "split DSR across chunks - part 1" do
      {response, buffer} = Dsr.scan("hello\e[", 24, 80)
      assert response == ""
      assert buffer == "hello\e["
    end

    test "split DSR across chunks - part 2" do
      {response1, buffer} = Dsr.scan("hello\e[", 24, 80)
      {response2, remaining} = Dsr.scan("6n", 24, 80, buffer)
      assert response1 == ""
      assert response2 == "\e[24;80R"
      assert remaining == "hello"
    end

    test "respects custom dimensions" do
      {response, _} = Dsr.scan("\e[6n", 50, 120)
      assert response == "\e[50;120R"
    end

    test "handles multiple queries" do
      {response, remaining} = Dsr.scan("\e[6ntest\e[6n", 24, 80)
      assert response == "\e[24;80R"
      assert String.contains?(remaining, "\e[6n")
    end
  end
end
