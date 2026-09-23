defmodule FreeqTagTest do
  use ExUnit.Case

  test "reads tag value from single tag" do
    line = "@batch=mlA :alice!a@h PRIVMSG #the-lab :bob: move"
    assert Freeq.Tag.read(line, "batch") == "mlA"
  end

  test "returns nil when line has no tag blob" do
    line = ":alice!a@h BATCH +mlA draft/multiline #the-lab"
    assert Freeq.Tag.read(line, "batch") == nil
  end

  test "finds tag in multi-tag blob" do
    line = "@+elita-ask=1;batch=mlA :alice!a@h PRIVMSG #the-lab :bob: move"
    assert Freeq.Tag.read(line, "batch") == "mlA"
  end

  test "returns empty string for bare tag" do
    line = "@batch=mlA;+elita-ask :alice!a@h PRIVMSG #the-lab :bob: move"
    assert Freeq.Tag.read(line, "+elita-ask") == ""
  end

  test "reads tag from batch opener line" do
    line = "@+elita-ask=1 :alice!a@h BATCH +mlA draft/multiline #the-lab"
    assert Freeq.Tag.read(line, "+elita-ask") == "1"
  end
end
