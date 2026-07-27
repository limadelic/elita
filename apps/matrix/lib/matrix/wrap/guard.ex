defmodule Matrix.Wrap.Guard do
  @moduledoc false
  import Task, only: [shutdown: 2, await: 2]

  def await(task) do
    guard(task)
  catch
    :exit, error -> fault(error, task)
  end

  defp guard(task) do
    await(task, 90_000)
  rescue
    _ ->
      timed(task)
  end

  defp fault({:timeout, _}, task), do: timed(task)

  defp fault(_, task) do
    shutdown(task, 1)
    :forward
  end

  defp timed(task) do
    shutdown(task, 1)
    :forward
  end
end
