defmodule NapoDonenessTest do
  use Tester
  @moduletag :live
  @moduletag timeout: 180_000

  setup do
    System.put_env("LIVE", "1")

    on_exit(fn ->
      System.delete_env("LIVE")
    end)

    :ok
  end

  test "doneness: two children report done, parent combines" do
    spawn :alpha, ["napo"]
    spawn :beta, ["napo"]
    spawn :combo, ["napo"]

    tell :alpha, "name one risk of no liability cap when done tell combo"
    tell :beta, "name one risk of auto-renewal when done tell combo"
    tell :combo, "children are alpha, beta. combine tree_alpha and tree_beta into tree_combo"

    poll_for_results()
  end

  defp poll_for_results(retries \\ 15) do
    if retries == 0 do
      raise "Timeout: tree_alpha, tree_beta, or tree_combo not found after 150s"
    end

    Process.sleep(10_000)

    tree_alpha = read_mem("tree_alpha")
    tree_beta = read_mem("tree_beta")
    tree_combo = read_mem("tree_combo")

    if present?(tree_alpha) && present?(tree_beta) && present?(tree_combo) do
      assert is_binary(tree_alpha), "tree_alpha should be binary"
      assert is_binary(tree_beta), "tree_beta should be binary"
      assert is_binary(tree_combo), "tree_combo should be binary"
    else
      poll_for_results(retries - 1)
    end
  end

  defp read_mem(key) do
    :ets.tab2list(:mem_depth_global)
    |> Enum.find(fn {k, _} -> k == key end)
    |> case do
      {_, value} -> value
      nil -> nil
    end
  end

  defp present?(nil), do: false
  defp present?(_), do: true
end
