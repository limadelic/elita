defmodule El.Answer do
  @moduledoc false

  import Process, only: [send_after: 3, cancel_timer: 1]
  import String, only: [contains?: 2, replace: 3]

  def collect(timeout) do
    timer = send_after(self(), :timeout, timeout)
    result = gather("", timer)
    cancel_timer(timer)
    result
  end

  def await(ref, timeout) do
    get(ref, timeout)
  end

  defp get(ref, timeout) do
    receive do
      {^ref, answer} -> answer
    after
      timeout -> collect(timeout)
    end
  end

  defp gather(acc, timer) do
    receive do
      {:output, data} -> handle(acc, timer, data)
      :timeout -> text(acc)
    end
  end

  defp handle(acc, timer, data) do
    combined = acc <> data
    combined |> done?(acc) |> settle(combined, timer)
  end

  defp settle(true, combined, _timer) do
    text(combined)
  end

  defp settle(false, combined, timer) do
    gather(combined, timer)
  end

  defp done?(_combined, ""), do: false
  defp done?(combined, _acc), do: complete?(combined)

  defp complete?(combined) do
    contains?(combined, "\e[?2004h") or contains?(combined, "⏺")
  end

  defp text(input) do
    input |> codes() |> commands()
  end

  defp codes(text) do
    replace(text, ~r/\e\[[^a-zA-Z]*[a-zA-Z]/, "")
  end

  defp commands(text) do
    replace(text, ~r/\e\][^\e]*(?:\e\\|\x07)/, "")
  end
end
