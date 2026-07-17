defmodule El.Repl.Route do
  import El.Puppet, only: [ask: 2]
  import El.Sessions, only: [log: 1]
  import IO, only: [puts: 1]
  import String, only: [split: 3]
  import Utils.World, only: [agents: 0]
  import El.Distribution, only: [wait: 1]

  def route([name, "log"], _a, _p, _i), do: name |> log() |> puts()

  def route(_x, agent, puppet, input) do
    words = input |> split(" ", parts: 2)
    {response, target, pid} = via(words, puppet, input, agent)
    puts(response)
    result(target, agent, pid)
  end

  def result(_target, _agent, _pid), do: :ok

  def via([_w], p, i, agent), do: {ask(p, i), agent, p}
  def via([w, msg], p, _i, agent), do: send(w, msg, p, agent, w in agents())
  def via(_, p, i, agent), do: {ask(p, i), agent, p}

  def send(w, msg, p, _agent, true) do
    pid = choose(wait(w), p)
    {ask(pid, msg), w, pid}
  end

  def send(w, msg, p, agent, false) do
    {ask(p, w <> " " <> msg), agent, p}
  end

  def choose(nil, default), do: default
  def choose(:undefined, default), do: default
  def choose(t, _), do: t
end
