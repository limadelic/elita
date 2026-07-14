defmodule Agent.Watch do
  import Log, only: [answer: 2]
  import String, only: [trim: 1]
  import System, only: [monotonic_time: 1]

  def start(agent, question) do
    spawn(fn -> begin(agent, question) end)
  end

  defp begin(agent, question) do
    log("WATCHER START #{agent} #{question}\n")
    loop(agent, question, monotonic_time(:millisecond), 0)
  rescue
    e ->
      log("WATCHER ERROR #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  defp log(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end

  defp loop(agent, question, start, pos) do
    elapsed = monotonic_time(:millisecond) - start
    if elapsed > 7000 do
      :ok
    else
      case scan(question, pos) do
        {:found, text} -> answer(agent, trim(text))
        {:continue, newpos} -> sleep(agent, question, start, newpos)
        :wait -> sleep(agent, question, start, pos)
      end
    end
  end

  defp sleep(agent, question, start, pos) do
    Process.sleep(100)
    loop(agent, question, start, pos)
  end

  defp scan(question, pos) do
    Agent.Jsonl.find(question, pos)
  catch
    :exit, e ->
      log("WATCHER CATCH EXIT #{inspect(e)}\n")
      :wait
    k, r ->
      log("WATCHER CATCH #{k} #{inspect(r)}\n")
      :wait
  end
end
