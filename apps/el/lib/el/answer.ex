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
      {:output, data} ->
        combined = acc <> data
        if done?(combined, acc) do
          strip_ansi(combined)
        else
          receive_answer(combined, timer)
        end

      :timeout ->
        strip_ansi(acc)
    end
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
