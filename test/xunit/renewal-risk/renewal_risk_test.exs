defmodule RenewalRiskTest do
  use Tester
  import String, only: [contains?: 2, downcase: 1]

  @moduletag :xunit
  @moduletag :prose

  test "coordinator assesses multiple accounts and flags at-risk renewals" do
    spawn(:coordinator)

    accounts = """
    Account: acme
    Usage trend: 1000 per week dropping to 200 per week (80% decline)
    Support tickets: 5 critical issues in past 30 days
    Renewal date: 60 days from now
    ---
    Account: globex
    Usage trend: 800 per week stable
    Support tickets: 0 issues
    Renewal date: 180 days from now
    ---
    Account: initech
    Usage trend: 500 per week stable
    Support tickets: 3 routine issues
    Renewal date: 35 days from now
    """

    result = ask(:coordinator, accounts)

    spawned([:assessor_acme, :assessor_globex, :assessor_initech])

    assert contains?(downcase(result), "acme")
    assert contains?(downcase(result), "high-risk")
    assert contains?(downcase(result), "globex")
    assert contains?(downcase(result), "low-risk")
    assert contains?(downcase(result), "initech")
    assert contains?(downcase(result), "medium-risk")
  end
end
