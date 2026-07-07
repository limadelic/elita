defmodule El.Answer do
  @moduledoc false

  def collect(timeout) do
    receive_answer(timeout, "")
  end

  defp receive_answer(timeout, acc) do
    receive do
      {:output, data} -> handle_output(timeout, acc, data)
    after
      timeout -> strip_ansi(acc)
    end
  end

  defp handle_output(timeout, acc, data) do
    combined = acc <> data
    next(timeout, combined, done?(combined, acc))
  end

  defp next(_timeout, combined, true), do: strip_ansi(combined)
  defp next(timeout, combined, false), do: receive_answer(timeout, combined)

  defp done?(_combined, ""), do: false
  defp done?(combined, _acc), do: String.contains?(combined, "\e[?2004h")

  defp strip_ansi(text) do
    text |> strip_csi() |> strip_osc()
  end

  defp strip_csi(text) do
    String.replace(text, ~r/\e\[[^a-zA-Z]*[a-zA-Z]/, "")
  end

  defp strip_osc(text) do
    String.replace(text, ~r/\e\][^\e]*(?:\e\\|\x07)/, "")
  end
end
