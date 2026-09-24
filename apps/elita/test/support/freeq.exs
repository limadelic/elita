defmodule Freeq do
  import :gen_tcp, only: [connect: 3, recv: 3, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]
  import Kernel, except: [spawn: 1]

  def spawn(agent) do
    agent_str = to_string(agent)
    Tester.spawn(agent)
    sock = connect_irc()
    join_channel(sock, agent_str, "#the-lab")
    pid = start_keeper()
    controlling_process(sock, pid)
    {:ok, sock, pid, "#the-lab", agent_str}
  end

  defp connect_irc do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    wait_ready(sock)
    sock
  end

  defp wait_ready(sock) do
    write(sock, "NICK temp\r\n")
    write(sock, "USER temp 0 * :temp\r\n")
    pattern = compile!("^:\\S+ 001 temp ")
    scan(sock, pattern)
  end

  defp join_channel(sock, agent, channel) do
    write(sock, "NICK #{agent}\r\n")
    write(sock, "USER #{agent} 0 * :#{agent}\r\n")
    write(sock, "JOIN #{channel}\r\n")
    wait_join(sock, agent, channel)
  end

  defp wait_join(sock, agent, channel) do
    pattern = compile!("^:\\S+ 366 #{escape(agent)} #{escape(channel)}")
    scan(sock, pattern)
  end

  defp write(sock, line) do
    :gen_tcp.send(sock, line)
  end

  defp scan(sock, regex) do
    {:ok, data} = recv(sock, 0, 5000)
    scan(sock, regex, to_string(data))
  end

  defp scan(sock, regex, "PING " <> server) do
    write(sock, "PONG #{trim(server)}\r\n")
    scan(sock, regex)
  end

  defp scan(sock, regex, line) do
    match(line =~ regex, sock, regex)
  end

  defp match(true, _sock, _regex), do: :ok
  defp match(false, sock, regex), do: scan(sock, regex)

  defp start_keeper do
    Kernel.spawn(&keeper/0)
  end

  defp keeper do
    receive do
      :stop -> :ok
    end
  end
end
