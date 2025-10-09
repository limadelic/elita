defmodule SilkdTest do
  use Tester

  setup_all do
    {:ok, pid} = Silkd.start_link()
    on_exit(fn -> GenServer.stop(pid) end)
    :ok
  end

  test "apply for a job" do
    silkd("apply_for_a_job")
  end

  test "close AIVA" do
    Silkd.weave(:navigate, %{url: "https://rec-preview.dlas1.ucloud.int/MORDOR"})

    content = Silkd.weave(:content)
    assert content["content"] =~ "AIVA Chat"
    assert content["content"] =~ ~s(style="display: block;")

    result = Silkd.weave(:click, %{selector: "button[aria-label='Close AIVA Chat']", wait: 500})
    assert result["status"] == "ok"

    content = Silkd.weave(:content)
    assert content["content"] =~ ~s(style="display: none;")
  end

  test "apply to engineering opportunity" do
    Silkd.weave(:navigate, %{url: "https://rec-preview.dlas1.ucloud.int/MORDOR"})

    search_input = ~s(input[aria-label="By job title, company, store or requisition number"])
    Silkd.weave(:type, %{selector: search_input, text: "engineer"})
    Silkd.weave(:press, %{key: "Enter", wait: 2000})

    result = Silkd.weave(:click, %{selector: ~s(ukg-link[data-automation="job-title"])})
    assert result["status"] == "ok"
  end
end
