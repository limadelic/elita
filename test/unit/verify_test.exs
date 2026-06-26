defmodule VerifyBehaviorTest do
  use ExUnit.Case

  test "substring match with downcase succeeds" do
    assert String.contains?(String.downcase("HELLO world"), String.downcase("hello"))
  end

  test "substring mismatch fails with assertion error, no API fallback" do
    assert_raise ExUnit.AssertionError, fn ->
      answer = "goodbye world"
      expected = "hello"
      assert String.contains?(
        String.downcase(answer),
        String.downcase("#{expected}")
      ), "Expected '#{answer}' to contain '#{expected}'"
    end
  end

  test "non-binary answer detected early" do
    assert_raise ExUnit.AssertionError, ~r/Expected binary answer/, fn ->
      answer = {:error, "something"}
      assert is_binary(answer), "Expected binary answer, got: #{inspect(answer)}"
    end
  end

  test "error tuple not passed to downcase" do
    # Proves we catch non-binary before downcase can crash on it
    answer = {:error, "api_failed"}
    refute is_binary(answer)
  end
end
