defmodule El.Cli.Parse do
  import Enum, only: [join: 2]

  @known_tools ["claude", "codex"]

  def name(["claude", name | _]), do: name
  def name(["claude"]), do: "default"
  def name(["ask", agent | _]), do: agent
  def name(["tell", agent | _]), do: agent
  def name(["spawn", _name, agent]), do: agent
  def name(["@" <> agent | _]), do: agent
  def name([tool, "ask", agent | _]) when tool in @known_tools, do: agent
  def name([tool, "tell", agent | _]) when tool in @known_tools, do: agent
  def name(["ls" | _]), do: "default"
  def name(["cd" | _]), do: "default"
  def name(["daemon"]), do: "default"
  def name([_config, "as", label]), do: label
  def name([agent | rest]) when length(rest) > 0, do: agent
  def name([agent]), do: agent
  def name([]), do: "el"

  def parse(["ask", agent, msg]), do: {:ask, nil, agent, msg}
  def parse(["tell", agent, msg]), do: {:tell, nil, agent, msg}
  def parse(["spawn", name, agent]), do: {:spawn, name, agent}
  def parse(["stop", agent]), do: {:stop, agent}
  def parse(["@" <> agent | rest]), do: {:ask_tool, agent, rest |> join(" ")}
  def parse([tool, "ask", agent, msg]), do: check(tool, {:ask, tool, agent, msg})
  def parse([tool, "tell", agent, msg]), do: check(tool, {:tell, tool, agent, msg})
  def parse(["claude"]), do: {:claude, :default}
  def parse(["claude", name]), do: {:claude, name}
  def parse(["ls"]), do: {:ls, nil}
  def parse(["ls", path]), do: {:ls, path}
  def parse(["cd", path]), do: {:cd, path}
  def parse(["daemon"]), do: :daemon
  def parse([]), do: {:repl, "el"}
  def parse([config, "as", name]), do: {:as, config, name}

  def parse([agent | rest]) when length(rest) > 0,
    do: {:repl_input, agent, join([agent | rest], " ")}

  def parse([agent]), do: {:repl, agent}
  def parse(_), do: :usage

  defp check(tool, cmd) when tool in @known_tools, do: cmd
  defp check(tool, _cmd), do: {:unknown_tool, tool}
end
