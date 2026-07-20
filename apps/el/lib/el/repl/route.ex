defmodule El.Repl.Route do
  import El.Puppet, only: [ask: 2]
  import El.Sessions, only: [log: 1]
  import IO, only: [puts: 1]
  import String, only: [split: 3]
  import Utils.World, only: [agents: 0]
  import El.Distribution, only: [wait: 1]
  import El.Distribution.Helpers, only: [find: 1]
  import Elita, only: [spawn: 2]

  def route([name, "log"], _a, _p, _i), do: name |> log() |> puts()

  def route(_x, agent, puppet, input) do
    {response, target, pid} = dispatch(input, puppet, agent)
    puts(response)
    result(target, agent, pid)
  end

  defp dispatch(input, puppet, agent) do
    words = input |> split(" ", parts: 3)
    attempt(words, puppet, input, agent)
  end

  def result(_target, _agent, _pid), do: :ok

  defp attempt([config, "as", name], _p, _i, _agent) do
    {:ok, pid} = spawn(name, [config])
    {name <> " spawned", name, pid}
  end

  defp attempt(_words, puppet, input, agent) do
    words = input |> split(" ", parts: 2)
    via(words, puppet, input, agent)
  end

  def via(["log"], _p, _i, agent), do: {agent |> log(), agent, nil}
  def via([_w], p, i, agent), do: {ask(p, i), agent, p}
  def via([w, msg], p, _i, agent), do: send(w, msg, p, agent, known?(w))
  def via(_, p, i, agent), do: {ask(p, i), agent, p}

  defp known?(w), do: w |> file?() |> settle(w)

  defp settle(true, _w), do: true
  defp settle(false, w), do: reg?(w)

  defp file?(w), do: w in agents()
  defp reg?(w), do: find(w) != nil

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
