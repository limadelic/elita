defmodule El.Answer do
  @moduledoc false

  import Process, only: [send_after: 3, cancel_timer: 1]
  import String, only: [contains?: 2, replace: 3]

  def collect(timeout) do
    timer = send_after(self(), :timeout, timeout)
    result = receive_answer("", timer)
    cancel_timer(timer)
    result
  end

  def await(ref, timeout) do
    recv(ref, timeout)
  end

  defp recv(ref, timeout) do
    receive do
      {^ref, answer} -> answer
    after timeout -> fallback()
    end
  end

  defp fallback do
    collect(0)
  end

  defp receive_answer(acc, timer) do
    receive do
      {:output, data} -> process_output(acc, timer, data)
      :timeout -> strip_ansi(acc)
    end
  end

  defp process_output(acc, timer, data) do
    combined = acc <> data
    combined |> done?(acc) |> finish_or_continue(combined, timer)
  end

  defp finish_or_continue(true, combined, _timer) do
    strip_ansi(combined)
  end

  defp finish_or_continue(false, combined, timer) do
    receive_answer(combined, timer)
  end

  defp done?(_combined, ""), do: false
  defp done?(combined, _acc), do: contains?(combined, "\e[?2004h")

  defp strip_ansi(text) do
    text |> strip_csi() |> strip_osc()
  end

  defp strip_csi(text) do
    replace(text, ~r/\e\[[^a-zA-Z]*[a-zA-Z]/, "")
  end

  defp strip_osc(text) do
    replace(text, ~r/\e\][^\e]*(?:\e\\|\x07)/, "")
  end
end
