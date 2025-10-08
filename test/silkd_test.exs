defmodule SilkdTest do
  use ExUnit.Case

  setup_all do
    {:ok, pid} = Silkd.start_link()
    on_exit(fn -> GenServer.stop(pid) end)
    :ok
  end

  test "google" do
    result = Silkd.navigate("https://www.google.com")
    assert result["status"] == "ok"
    assert result["url"] =~ "google.com"
  end

  test "close AIVA" do
    Silkd.navigate("https://rec-preview.dlas1.ucloud.int/MORDOR")

    before = Silkd.content()
    assert String.contains?(before["content"], "AIVA Chat")
    assert String.contains?(before["content"], ~s(style="display: block;"))

    result = Silkd.click("button[aria-label='Close AIVA Chat']", wait: 500)
    assert result["status"] == "ok"

    after_click = Silkd.content()
    assert String.contains?(after_click["content"], ~s(style="display: none;"))
  end
end
