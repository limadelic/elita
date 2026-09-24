defmodule Freeq do
  import :gen_tcp, only: [connect: 3, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1, run: 3]
  import Brian, except: [join: 2]
  import ExUnit.Callbacks, only: [on_exit: 1]
  import Elita, only: [request: 2]
  import Process, only: [get: 1, put: 2]
  import String, only: [split: 2, trim: 1]
  import Enum, only: [reject: 2, map: 2, filter: 2, join: 2]
  import File, only: [ls: 1, read: 1]
  import Path, only: [expand: 1]

  def spawn(agent) do
    spawn(agent, [agent])
  end

  def spawn(agent, config) do
    nick = to_string(agent)
    Tester.spawn(agent, config)
    sock = dial()
    enter(sock, nick, "#the-lab")
    pid = Kernel.spawn(&keeper/0)
    controlling_process(sock, pid)
    put(agent, sock)
    put({:pid, agent}, pid)

    on_exit(fn ->
      part(sock, "#the-lab", nick)
      quit(sock)
      send(pid, :stop)
    end)

    pause()
  end

  defp dial do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    auth(sock)
    sock
  end

  defp auth(sock) do
    write(sock, "NICK temp\r\n")
    write(sock, "USER temp 0 * :temp\r\n")
    pattern = compile!("^:\\S+ 001 temp ")
    scan(sock, pattern)
  end

  defp blank(text) do
    trim(text) == ""
  end

  defp enter(sock, agent, channel) do
    write(sock, "NICK #{agent}\r\n")
    write(sock, "USER #{agent} 0 * :#{agent}\r\n")
    write(sock, "JOIN #{channel}\r\n")
    pattern = compile!("^:\\S+ 366 #{escape(agent)} #{escape(channel)}")
    scan(sock, pattern)
  end

  def ask(agent, msg) do
    name = to_string(agent)
    say(room(), msg)
    reply = request(name, msg)
    sock = get(agent)
    pattern = compile!("^:#{escape(name)}!\\S+ PRIVMSG #the-lab :(.*)")

    texts =
      reply
      |> split("\n")
      |> reject(&blank/1)
      |> map(&emit(sock, pattern, &1))

    delegations(name, sock)
    texts |> join("\n")
  end

  def tell(agent, msg) do
    say(room(), msg)
    Tester.tell(agent, msg)
  end

  defp emit(sock, pattern, line) do
    write(sock, "PRIVMSG #the-lab :#{line}\r\n")
    grab(room() |> elem(0), pattern)
  end

  defp delegations(agent, sock) do
    pattern = compile!("^:#{escape(agent)}!\\S+ PRIVMSG #the-lab :(.*)")

    log(agent)
    |> split("\n")
    |> reject(&blank/1)
    |> map(&shout(&1, agent))
    |> reject(&is_nil/1)
    |> map(&emit(sock, pattern, &1))
  end

  defp log(agent) do
    dir = expand("~/.elita/sessions")
    pattern = compile!("^#{escape(agent)}_\\d+\\.log$")
    ls(dir) |> logs_from(pattern, dir)
  end

  defp logs_from({:ok, files}, pattern, dir) do
    files
    |> filter(&run(pattern, &1, []))
    |> first(dir)
  end

  defp logs_from(_, _pattern, _dir), do: ""

  defp first([], _dir), do: ""

  defp first([file | _], dir) do
    read(Path.join(dir, file)) |> fetch_content()
  end

  defp fetch_content({:ok, content}), do: content
  defp fetch_content(_), do: ""

  defp shout(line, agent) do
    pattern = compile!("^📢 #{escape(agent)} → ([^:]+): (.*)$")

    case run(pattern, trim(line), capture: :all_but_first) do
      [recipient, msg] -> "#{recipient}: #{msg}"
      _ -> nil
    end
  end

  defp room, do: get(:room)
end
