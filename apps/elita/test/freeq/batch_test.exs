defmodule FreeqBatchTest do
  use ExUnit.Case

  test "two batches open at once" do
    Process.delete(:freeq_batch)

    lines = [
      ":alice!a@h BATCH +mlA draft/multiline #the-lab",
      "@batch=mlA :alice!a@h PRIVMSG #the-lab :bob: move",
      ":bob!b@h BATCH +mlB draft/multiline #the-lab",
      "@batch=mlB :bob!b@h PRIVMSG #the-lab :alice: reply",
      "@batch=mlA :alice!a@h PRIVMSG #the-lab :O | X | O",
      "BATCH -mlA",
      "BATCH -mlB"
    ]

    result = Freeq.Batch.absorb(lines)

    expected = [
      ":alice!a@h PRIVMSG #the-lab :bob: move\nO | X | O",
      ":bob!b@h PRIVMSG #the-lab :alice: reply"
    ]

    assert result == expected
  end
end
