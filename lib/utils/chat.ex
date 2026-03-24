defmodule Chat do
  import String, only: [trim: 1]
  import IO, only: [puts: 2, write: 2, read: 2]
  import Elita, only: [start: 2, call: 2]
  import Node, only: [start: 1]

  def main(argv) do
    nifs()
    argv
    |> parse()
    |> run()
  end

  defp nifs do
    base = :escript.script_name() |> to_string() |> Path.dirname()
    env = System.get_env("MIX_ENV") || "dev"

    roots =
      [
        Path.join(base, "_build/#{env}/lib"),
        Path.join(base, "_build/dev/lib")
      ]
      |> Enum.uniq()

    roots =
      if System.get_env("ELITA_PATHS") == "1" do
        (roots ++
           [
             Path.join(base, "_build/test/lib"),
             Path.join(base, "_build/prod/lib")
           ])
        |> Enum.uniq()
      else
        roots
      end

    Enum.each(roots, &add_lib_paths/1)
  end

  defp add_lib_paths(lib) do
    if File.dir?(lib) do
      lib
      |> File.ls!()
      |> Enum.each(fn app ->
        ebin = Path.join([lib, app, "ebin"])
        if File.dir?(ebin), do: :code.add_patha(~c"#{ebin}")
      end)
    end
  end

  defp parse(argv) do
    {dist, rest} = flags(argv)

    case rest do
      [name] -> {:ok, name, name, dist}
      [agent, name] -> {:ok, agent, name, dist}
      _ -> {:error, :usage}
    end
  end

  defp flags(argv) do
    dist = Enum.member?(argv, "--dist")
    rest = Enum.reject(argv, &(&1 == "--dist"))
    {dist, rest}
  end

  defp run({:ok, agent, name, dist}) do
    net(dist, name)

    case start(agent, [agent]) do
      {:ok, _pid} ->
        tip(dist)
        repl(agent, name)

      {:error, reason} ->
        puts(:stderr, "failed to start agent: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp run({:error, :usage}) do
    puts(:stderr, usage())
    System.halt(1)
  end

  defp usage do
    """
    usage: elita <agent> [--dist]
           elita <agent> <name> [--dist]

    --dist  start Erlang distribution (needs epmd; run epmd -daemon if you see inet_tcp errors)
    ELITA_PATHS=1  add _build/test and _build/prod lib paths (escript helper)
    """
  end

  defp net(true, name) do
    start(:"#{name}@127.0.0.1")
    puts(:stderr, hint())
  end

  defp net(false, _), do: :ok

  defp tip(false) do
    puts(
      :stderr,
      "Tip: run the same command with --dist to start Erlang distribution; if that errors, run epmd -daemon first.\n"
    )
  end

  defp tip(true), do: :ok

  defp hint do
    """
    Distribution on (node #{inspect(node())}).
    If you see inet_tcp / econnrefused, run: epmd -daemon
    """
  end

  defp repl(agent, name) do
    prompt(name)

    case read(:stdio, :line) do
      :eof ->
        puts(:stderr, "Bye!")

      line ->
        call(agent, trim(line))
        repl(agent, name)
    end
  end

  defp prompt(name) do
    write(:stderr, "#{name} > ")
  end
end
