defmodule Elita.Vault do
  def save(name, history) do
    vsn = bump(name)
    :ets.insert(:elita_vault, {name, vsn, history})
    :ok
  end

  def load(name) do
    wrap(read(name))
  end

  defp bump(name) do
    add(settle(check(name)))
  end

  defp wrap(nil), do: []
  defp wrap(val), do: val

  defp settle(nil), do: 0
  defp settle(val), do: val

  defp add(val), do: val + 1

  defp check(name) do
    found(lookup(name))
  end

  defp read(name) do
    hist(lookup(name))
  end

  defp lookup(name) do
    :ets.lookup(:elita_vault, name)
  end

  defp found([{_name, vsn, _history}]), do: vsn
  defp found([]), do: nil

  defp hist([{_name, _vsn, history}]), do: history
  defp hist([]), do: nil
end
