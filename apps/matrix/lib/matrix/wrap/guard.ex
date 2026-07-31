defmodule Matrix.Wrap.Guard do
  @moduledoc false
  import Task, only: [shutdown: 2, await: 2]

  def await(task) do
    guard(task)
  catch
    :exit, _ -> cleanup(task)
  end

  defp guard(task) do
    await(task, 90_000)
  end

  defp cleanup(task) do
    shutdown(task, 1)
    :forward
  end
end
