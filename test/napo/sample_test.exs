defmodule NapoSampleTest do
  use Tester
  @moduletag :live
  @moduletag timeout: 180_000

  setup do
    System.put_env("LIVE", "1")
    System.put_env("CASSETTE", "sample")

    unless System.get_env("TAPE") do
      System.put_env("TAPE", "replay")
    end

    on_exit(fn ->
      System.delete_env("LIVE")
      System.delete_env("CASSETTE")
      System.delete_env("TAPE")
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

  test "contract review: vendor agreement with red flags" do
    spawn :f2, ["napo"]
    spawn :l2, ["napo"]
    spawn :o2, ["napo"]
    spawn :combo2, ["napo"]

    contract = vendor_agreement_text()

    tell :f2, "Review this vendor agreement for financial risks: #{contract}. When done, set tree_f2 and tell combo2."
    tell :l2, "Review this vendor agreement for liability risks: #{contract}. When done, set tree_l2 and tell combo2."
    tell :o2, "Review this vendor agreement for operational risks: #{contract}. When done, set tree_o2 and tell combo2."
    tell :combo2, "Children are f2, l2, o2. Combine tree_f2, tree_l2, and tree_o2 into tree_combo2 when all report done."

    poll_for_results_vendor()
  end

  test "contract review: office lease with red flags" do
    spawn :f3, ["napo"]
    spawn :l3, ["napo"]
    spawn :o3, ["napo"]
    spawn :combo3, ["napo"]

    contract = office_lease_text()

    tell :f3, "Review this office lease for financial risks: #{contract}. When done, set tree_f3 and tell combo3."
    tell :l3, "Review this office lease for liability risks: #{contract}. When done, set tree_l3 and tell combo3."
    tell :o3, "Review this office lease for operational risks: #{contract}. When done, set tree_o3 and tell combo3."
    tell :combo3, "Children are f3, l3, o3. Combine tree_f3, tree_l3, and tree_o3 into tree_combo3 when all report done."

    poll_for_results_lease()
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

  defp vendor_agreement_text do
    """
    VENDOR/SUPPLIER AGREEMENT

    1. Service Levels: Vendor agrees to maintain 99% uptime without service level agreement remedy or credits for breaches.

    2. Pricing: Vendor may unilaterally increase pricing at any time with 30 days' notice. Client must accept or terminate contract.

    3. Auto-Renewal: Contract auto-renews annually unless client provides 90-day written notice before renewal. Failure to provide notice locks client into additional year.

    4. Indemnification: Client indemnifies vendor against all claims, damages, and liabilities arising from client's use of services, including vendor's negligence or misconduct.

    5. Payment Terms: Client must pay 50% upfront, non-refundable. Remaining 50% due upon completion. No disputes regarding invoices permitted after 10 days.

    6. Termination: Vendor may terminate for any reason without cause. Client may only terminate for material breach, which is not clearly defined.

    7. Intellectual Property: All deliverables, methodologies, and tools developed remain vendor's property. Client receives only limited license, non-exclusive and revocable.

    8. Liability Caps: Client's liability is unlimited. Vendor's liability is capped at fees paid in prior month, regardless of damage severity.

    9. Confidentiality: Vendor may disclose client information to subcontractors and partners without consent or notice.

    10. Dispute Resolution: All disputes resolved through arbitration at client's expense in vendor's chosen jurisdiction.
    """
  end

  defp office_lease_text do
    """
    COMMERCIAL OFFICE LEASE

    1. Base Rent: $5,000 monthly rent for 5,000 sq ft office space. Rent increases 3% annually.

    2. Triple-Net Costs: Tenant responsible for 100% of property taxes, insurance, CAM charges, and maintenance. CAM estimated at $2,500/month but actual costs unknown.

    3. Personal Guarantee: Tenant owner must personally guarantee all lease obligations, creating personal liability beyond business entity.

    4. Sublease Restrictions: Tenant may not sublease, assign, or transfer lease without landlord's written consent, which may be withheld in landlord's sole discretion.

    5. Renewal Options: No renewal options or renewal rights. At lease end, landlord determines new terms with no guaranteed continued occupancy.

    6. Early Termination: Landlord may terminate lease without cause with 30 days' notice. Tenant may not terminate early except by paying 12 months' remaining rent.

    7. Maintenance & Repairs: Tenant responsible for all repairs and maintenance, interior and exterior. Landlord has no maintenance obligations.

    8. Insurance Requirements: Tenant must carry $2M liability insurance, property insurance, and workers' compensation coverage naming landlord as additional insured.

    9. Default Provisions: Failure to pay rent by day 3 of month constitutes material default. Landlord may immediately terminate and pursue eviction.

    10. Dispute Resolution: All disputes resolved through litigation in landlord's county. Tenant responsible for landlord's attorney fees if lawsuit contested.
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

  defp poll_for_results_vendor(retries \\ 15) do
    if retries == 0 do
      raise "Timeout: tree_f2, tree_l2, tree_o2, or tree_combo2 not found after 150s"
    end

    Process.sleep(10_000)

    tree_f2 = read_mem("tree_f2")
    tree_l2 = read_mem("tree_l2")
    tree_o2 = read_mem("tree_o2")
    tree_combo2 = read_mem("tree_combo2")

    if present?(tree_f2) && present?(tree_l2) && present?(tree_o2) && present?(tree_combo2) do
      assert is_binary(tree_f2), "tree_f2 should be binary"
      assert is_binary(tree_l2), "tree_l2 should be binary"
      assert is_binary(tree_o2), "tree_o2 should be binary"
      assert is_binary(tree_combo2), "tree_combo2 should be binary"

      combo_text = String.downcase(tree_combo2)
      facet_mentions = count_facet_mentions_vendor(combo_text)
      assert facet_mentions >= 2, "tree_combo2 should integrate findings from at least 2 facets, found #{facet_mentions}"
    else
      poll_for_results_vendor(retries - 1)
    end
  end

  defp poll_for_results_lease(retries \\ 15) do
    if retries == 0 do
      raise "Timeout: tree_f3, tree_l3, tree_o3, or tree_combo3 not found after 150s"
    end

    Process.sleep(10_000)

    tree_f3 = read_mem("tree_f3")
    tree_l3 = read_mem("tree_l3")
    tree_o3 = read_mem("tree_o3")
    tree_combo3 = read_mem("tree_combo3")

    if present?(tree_f3) && present?(tree_l3) && present?(tree_o3) && present?(tree_combo3) do
      assert is_binary(tree_f3), "tree_f3 should be binary"
      assert is_binary(tree_l3), "tree_l3 should be binary"
      assert is_binary(tree_o3), "tree_o3 should be binary"
      assert is_binary(tree_combo3), "tree_combo3 should be binary"

      combo_text = String.downcase(tree_combo3)
      facet_mentions = count_facet_mentions_lease(combo_text)
      assert facet_mentions >= 2, "tree_combo3 should integrate findings from at least 2 facets, found #{facet_mentions}"
    else
      poll_for_results_lease(retries - 1)
    end
  end

  defp count_facet_mentions(combo_text) do
    count = 0
    count = if String.contains?(combo_text, ["financial", "salary", "compensation", "overtime"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["liability", "dispute", "arbitration", "non-compete"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["operational", "hours", "remote", "probation"]), do: count + 1, else: count
    count
  end

  defp count_facet_mentions_vendor(combo_text) do
    count = 0
    count = if String.contains?(combo_text, ["pricing", "upfront", "payment", "refundable"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["indemnity", "indemnification", "liability", "negligence"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["auto-renewal", "uptime", "sla", "service level"]), do: count + 1, else: count
    count
  end

  defp count_facet_mentions_lease(combo_text) do
    count = 0
    count = if String.contains?(combo_text, ["triple-net", "cam", "taxes", "insurance"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["personal guarantee", "indemnity", "eviction", "liability"]), do: count + 1, else: count
    count = if String.contains?(combo_text, ["sublease", "renewal", "termination", "maintenance"]), do: count + 1, else: count
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
