defmodule NapoSampleTest do
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

  test "contract review: three facets analyze employment contract, parent combines" do
    spawn :financial, ["napo"]
    spawn :liability, ["napo"]
    spawn :operational, ["napo"]
    spawn :combo, ["napo"]

    contract = contract_text()

    tell :financial, "Review this employment contract for financial risks: #{contract}. When done, set tree_financial and tell combo."
    tell :liability, "Review this employment contract for liability risks: #{contract}. When done, set tree_liability and tell combo."
    tell :operational, "Review this employment contract for operational risks: #{contract}. When done, set tree_operational and tell combo."
    tell :combo, "Children are financial, liability, operational. Combine tree_financial, tree_liability, and tree_operational into tree_combo when all report done."

    poll_for_results()
  end

  defp contract_text do
    """
    EMPLOYMENT AGREEMENT

    1. Position & Compensation: $60,000 annual salary, paid bi-weekly.

    2. Hours & Overtime: Employee expected to work 40+ hours per week. Overtime hours are not compensated.

    3. Non-Compete: Employee agrees not to work in this industry for 2 years following termination of employment.

    4. IP Assignment: All work product, inventions, and creative works, including personal projects developed using any company resources, knowledge, or during company time, becomes exclusive property of the company.

    5. Confidentiality: Employee maintains strict confidentiality of all company information, trade secrets, and client data during and after employment.

    6. At-Will Employment: Either party may terminate employment at any time without cause, notice, or explanation. No severance package provided upon termination.

    7. Probationary Period: First 90 days constitute probation with identical terms and no additional protections.

    8. Remote Work: Remote work is prohibited without explicit written approval requested and granted for each specific instance.

    9. Benefits: Health insurance offered after 90-day probation. No retirement plan or matching contributions provided.

    10. Dispute Resolution: All disputes shall be resolved through mandatory binding arbitration at employee's expense.
    """
  end

  defp poll_for_results(retries \\ 15) do
    if retries == 0 do
      raise "Timeout: tree_financial, tree_liability, tree_operational, or tree_combo not found after 150s"
    end

    Process.sleep(10_000)

    tree_financial = read_mem("tree_financial")
    tree_liability = read_mem("tree_liability")
    tree_operational = read_mem("tree_operational")
    tree_combo = read_mem("tree_combo")

    if present?(tree_financial) && present?(tree_liability) && present?(tree_operational) && present?(tree_combo) do
      assert is_binary(tree_financial), "tree_financial should be binary"
      assert is_binary(tree_liability), "tree_liability should be binary"
      assert is_binary(tree_operational), "tree_operational should be binary"
      assert is_binary(tree_combo), "tree_combo should be binary"

      combo_text = String.downcase(tree_combo)
      facet_mentions = count_facet_mentions(combo_text)
      assert facet_mentions >= 2, "tree_combo should integrate findings from at least 2 facets, found #{facet_mentions}"
    else
      poll_for_results(retries - 1)
    end
  end

  defp count_facet_mentions(combo_text) do
    count = 0
    count = if String.contains?(combo_text, ["financial", "salary", "compensation", "overtime"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["liability", "dispute", "arbitration", "non-compete"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["operational", "hours", "remote", "probation"]), do: count + 1, else: count
    count
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
