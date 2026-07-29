defmodule Matrix.Pty.Retry do
  @moduledoc false
  import Process, only: [send_after: 3]
  import Map, only: [merge: 2]

  @start_ms 1_000
  @cap_ms 10_000
  @budget_ms 60_000
  @ask_timeout_ms 300_000

  def validate, do: check(@budget_ms >= @ask_timeout_ms)

  defp check(true) do
    raise "Pty retry budget (#{@budget_ms}ms) must be < ask timeout (#{@ask_timeout_ms}ms)"
  end

  defp check(false), do: :ok

  def init do
    %{attempt: 0, total: 0}
  end

  def calculate(state) do
    attempt = state[:attempt]
    delay = delay(attempt)
    total = state[:total] + delay
    {delay, merge(state, %{attempt: attempt + 1, total: total})}
  end

  def exhausted?(state) do
    state[:total] >= @budget_ms
  end

  def schedule(pid, state) do
    {delay_ms, new_state} = calculate(state)
    send_after(pid, :retry_pty, delay_ms)
    new_state
  end

  defp delay(0), do: @start_ms
  defp delay(1), do: 2_000
  defp delay(2), do: 4_000
  defp delay(3), do: 8_000
  defp delay(_), do: @cap_ms

  def budget, do: @budget_ms
  def cap, do: @cap_ms
end
