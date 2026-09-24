defmodule Freeq do
  import :gen_tcp, only: [connect: 3, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import Brian
  import ExUnit.Callbacks, only: [on_exit: 1]
  import Elita, only: [request: 2]

  def spawn(agent) do
    nick = to_string(agent)
    Tester.spawn(agent)
    sock = dial()
    enter(sock, nick, "#the-lab")
    pid = Kernel.spawn(&keeper/0)
    controlling_process(sock, pid)
    Process.put(agent, sock)
    Process.put({:pid, agent}, pid)

    on_exit(fn ->
      part(sock, "#the-lab", nick)
      quit(sock)
      send(pid, :stop)
    end)
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

  defp enter(sock, agent, channel) do
    write(sock, "NICK #{agent}\r\n")
    write(sock, "USER #{agent} 0 * :#{agent}\r\n")
    write(sock, "JOIN #{channel}\r\n")
    pattern = compile!("^:\\S+ 366 #{escape(agent)} #{escape(channel)}")
    scan(sock, pattern)
  end

  def ask(agent, msg) do
    talk(room(), msg)
    reply = request(to_string(agent), msg)
    sock = Process.get(agent)
    write(sock, "PRIVMSG #the-lab :#{reply}\r\n")
    pattern = compile!("^:greet!\\S+ PRIVMSG #the-lab :(.*)")
    text = grab(room() |> elem(0), pattern)
    bubble(reply)
    text
  end

  defp room, do: Process.get(:room)

  defp talk(room, msg) do
    {sock, _, channel, nick} = room
    write(sock, "PRIVMSG #{channel} :#{msg}\r\n")
    pattern = compile!("^:#{escape(nick)}!\\S+ PRIVMSG #{channel} :#{escape(msg)}\\r?$")
    scan(sock, pattern)
  end

  defp bubble(text) do
    time = 4500 + String.length(text) * 30
    Process.sleep(time)
  end
end
