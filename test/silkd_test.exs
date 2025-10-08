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

    assert Silkd.contains?("AIVA Chat")
    assert Silkd.contains?(~s(style="display: block;"))

    result = Silkd.click("button[aria-label='Close AIVA Chat']", wait: 500)
    assert result["status"] == "ok"

    assert Silkd.contains?(~s(style="display: none;"))
  end

  test "apply to engineering opportunity" do
    Silkd.navigate("https://rec-preview.dlas1.ucloud.int/MORDOR")

    search_input = ~s(input[aria-label="By job title, company, store or requisition number"])
    Silkd.type(search_input, "engineer")
    Silkd.press("Enter", wait: 2000)

    result = Silkd.click(~s(ukg-link[data-automation="job-title"]))
    assert result["status"] == "ok"
  end
end
