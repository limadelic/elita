defmodule TriageTest do
  use Tester
  import String, only: [contains?: 2, downcase: 1]

  @moduletag :xunit

  test "triage fans out to classifiers and merges verdicts" do
    spawn(:triage)

    emails = """
    Email 1: Subject: Urgent payment overdue. Body: Your billing is past due.
    Email 2: Subject: Claim your free prize! Body: You've won a promotional offer!
    Email 3: Subject: New feature request. Body: Please add dark mode to the app.
    """

    result = ask(:triage, emails)

    assert contains?(downcase(result), downcase("urgent"))
    assert contains?(downcase(result), downcase("spam"))
    assert contains?(downcase(result), downcase("feature"))
  end
end
