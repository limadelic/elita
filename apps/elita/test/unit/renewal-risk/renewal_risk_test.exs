defmodule RenewalRiskUnitTest do
  use Tester

  @moduletag :main
  @moduletag :prose

  setup do
    System.put_env("CASSETTE", "renewal-risk")

    on_exit(fn ->
      System.delete_env("CASSETTE")
    end)

    spawn(:coordinator)
    spawn(:judge)
    :ok
  end

  test "coordinator assesses multiple accounts and flags at-risk renewals" do
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

    judge(result, "result mentions acme account")
    judge(result, "result mentions globex account")
    judge(result, "result mentions initech account")
    judge(result, "result includes risk assessment for acme")
    judge(result, "result includes risk assessment for globex")
    judge(result, "result includes risk assessment for initech")
  end
end
