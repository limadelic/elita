defmodule NapoContractTest do
  use Tester
  @moduletag :live

  setup do
    System.put_env("LIVE", "1")

    on_exit(fn ->
      System.delete_env("LIVE")
    end)

    spawn :napo
    :ok
  end

  test "shape: MSA review forces split into facets" do
    problem = """
    Review this master services agreement and produce the complete risk assessment: \
    every risky clause identified, why risky, severity, negotiation ask. Nothing material missed.

    MASTER SERVICES AGREEMENT

    1. SERVICES: Provider will deliver cloud infrastructure services as detailed in attached SOW.
    2. SERVICE LEVEL: 99.5% uptime SLA, monitored monthly.
    3. INCIDENT RESPONSE: Provider commits to 4-hour response time for critical incidents.
    4. FEES: Annual subscription of $500,000, due quarterly in advance.
    5. PRICE ESCALATION: Provider may increase fees by up to 15% annually with 30-day notice.
    6. PAYMENT TERMS: Net 30 from invoice; late payments incur 2% monthly interest.
    7. TAXES: Customer responsible for all applicable taxes except income tax.
    8. PROFESSIONAL SERVICES: Additional services billed at $250/hour, invoiced monthly.
    9. LIABILITY LIMITATION: Provider's total liability capped at one month of fees paid ($41,667).
    10. CONSEQUENTIAL DAMAGES: Neither party liable for indirect, incidental, or consequential damages.
    11. INDEMNIFICATION: Customer shall indemnify Provider for any third-party claims without limitation.
    12. IP OWNERSHIP: Provider retains all IP in the platform; Customer retains IP in custom code.
    13. CUSTOMER DATA: Provider may use anonymized customer data to improve AI models and services.
    14. DATA RETENTION: Upon termination, Provider retains data for 90 days for compliance purposes.
    15. AUDIT RIGHTS: Customer may audit Provider's infrastructure quarterly with 2 weeks notice.
    16. SECURITY: Provider maintains industry-standard security controls reviewed annually.
    17. ENCRYPTION: Data in transit encrypted with TLS 1.2; at-rest encryption available for additional fee.
    18. COMPLIANCE: Provider complies with GDPR, SOC 2, and applicable laws.
    19. EXPORT CONTROL: Customer warrants compliance with export control regulations.
    20. SUBCONTRACTORS: Provider may use subcontractors without prior Customer notice.
    21. TERM: Initial term of 3 years; auto-renews for successive 12-month periods.
    22. RENEWAL NOTICE: Either party must provide 120-day written notice to not renew.
    23. EARLY TERMINATION: Customer may terminate for convenience with 12 months notice and 50% penalty.
    24. FOR CAUSE TERMINATION: Breach with 30-day cure period permits immediate termination.
    25. TRANSITION ASSISTANCE: Provider provides 30 days transition support at no additional charge.
    26. CONFIDENTIALITY: Each party maintains confidentiality for 5 years post-termination.
    27. DISPUTE RESOLUTION: All disputes resolved exclusively in courts of Grand Cayman Islands.
    28. GOVERNING LAW: Agreement governed by laws of Grand Cayman Islands.
    29. INSURANCE: Provider maintains liability insurance at minimum $1M per occurrence.
    30. FORCE MAJEURE: Neither party liable for performance failures due to force majeure events.
    31. ENTIRE AGREEMENT: This agreement supersedes all prior understandings and agreements.
    32. SEVERABILITY: If any provision invalid, others remain in full force and effect.
    33. ASSIGNMENT: Neither party may assign without the other's written consent.
    34. AMENDMENTS: Amendments must be in writing and signed by both parties' authorized representatives.
    35. NOTICES: Legal notices sent to addresses listed in signature block, effective upon receipt.
    """

    ask :napo, problem

    children = extract_depth_children()
    assert length(children) >= 2,
           "Should have at least 2 child facets spawned, got: #{inspect(children)}"
  end

  defp extract_depth_children do
    :ets.tab2list(:mem_depth_global)
    |> Enum.filter(fn {key, value} ->
      is_binary(key) && String.starts_with?(key, "depth_") && value == "1"
    end)
    |> Enum.map(fn {key, _value} ->
      String.replace_prefix(key, "depth_", "")
    end)
    |> Enum.sort()
  end
end
