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

end
