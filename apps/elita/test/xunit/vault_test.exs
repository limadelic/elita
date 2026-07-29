defmodule VaultTest do
  use ExUnit.Case

  test "save and load checkpoint" do
    history = [:msg1, :msg2]
    :ok = Elita.Vault.save("agent1", history)
    assert history == Elita.Vault.load("agent1")
  end

  test "load returns empty for missing agent" do
    assert [] == Elita.Vault.load("missing_agent")
  end

  test "save increments version" do
    :ok = Elita.Vault.save("agent2", [:msg1])
    vsn1 = get_vsn("agent2")

    :ok = Elita.Vault.save("agent2", [:msg1, :msg2])
    vsn2 = get_vsn("agent2")

    assert vsn2 > vsn1
  end

  defp get_vsn(name) do
    [{_name, vsn, _history}] = :ets.lookup(:elita_vault, name)
    vsn
  end
end
