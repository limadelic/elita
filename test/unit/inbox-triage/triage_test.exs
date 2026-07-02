defmodule TriageUnitTest do
  use Tester
  @moduletag :main
  @moduletag :prose

  setup do
    System.put_env("CASSETTE", "inbox-triage")

    on_exit(fn ->
      System.delete_env("CASSETTE")
    end)

    spawn(:triage)
    spawn(:judge)
    :ok
  end

  test "triage fans out to classifiers and merges verdicts" do
    emails = """
    Email 1: Subject: Urgent payment overdue. Body: Your billing is past due.
    Email 2: Subject: Claim your free prize! Body: You've won a promotional offer!
    Email 3: Subject: New feature request. Body: Please add dark mode to the app.
    """

    result = ask(:triage, emails)

    spawned([:classifier_1, :classifier_2, :classifier_3])

    judge(result, "summary lists urgent as a classification")
    judge(result, "summary lists spam as a classification")
    judge(result, "summary lists feature as a classification")
  end
end
