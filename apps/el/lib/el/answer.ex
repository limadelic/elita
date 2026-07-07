defmodule El.Answer do
  @moduledoc false

  def collect(timeout) do
    timer = Process.send_after(self(), :timeout, timeout)
    result = receive_answer("", timer)
    Process.cancel_timer(timer)
    result
  end

  defp receive_answer(acc, timer) do
    receive do
      {:output, data} -> process_output(acc, timer, data)
      :timeout -> strip_ansi(acc)
    end
  end

  defp process_output(acc, timer, data) do
    combined = acc <> data
    combined
    |> done?(acc)
    |> finish_or_continue(combined, timer)
  end

  defp finish_or_continue(true, combined, _timer) do
    strip_ansi(combined)
  end

  defp finish_or_continue(false, combined, timer) do
    receive_answer(combined, timer)
  end

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
