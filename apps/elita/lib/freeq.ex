defmodule Elita.Freeq do
  use GenServer

  import Keyword, only: [fetch!: 2]
  import String, only: [contains?: 2, trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [spawn: 2]

  def start_link(opts) do
    nick = fetch!(opts, :nick)
    channel = fetch!(opts, :channel)
    start_link(__MODULE__, {nick, channel}, [])
  end

  def say(pid, text) do
    call(pid, {:say, text})
  end

  @impl true
  def init({nick, channel}) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    boot(socket, nick, channel)
    {:ok, _} = spawn(nick, [nick])
    {:ok, %{socket: socket, nick: nick, channel: channel}}
  end

  @impl true
  def handle_call({:say, text}, _from, %{socket: socket, channel: channel} = state) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:tcp, _socket, line}, state) do
    line |> to_string() |> trim_trailing("\r\n") |> handle(state)
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  defp boot(socket, nick, channel) do
    :gen_tcp.send(socket, "NICK #{nick}\r\n")
    :gen_tcp.send(socket, "USER #{nick} 0 * :#{nick}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp handle("PING " <> server, %{socket: socket} = state) do
    :gen_tcp.send(socket, "PONG #{server}\r\n")
    {:noreply, state}
  end

  defp handle(":" <> msg, %{nick: nick, channel: channel, socket: socket} = state) do
    privmsg(msg, nick, channel, socket)
    {:noreply, state}
  end

  defp handle(_msg, state) do
    {:noreply, state}
  end

  defp privmsg(msg, nick, channel, socket) do
    privmsg(contains?(msg, "PRIVMSG"), msg, nick, channel, socket)
  end

  defp privmsg(true, msg, nick, channel, socket) do
    Elita.Freeq.Parser.parse(msg, nick, channel)
    |> reply(socket, channel, nick)
  end

  defp privmsg(false, _msg, _nick, _channel, _socket) do
    :noop
  end

  defp reply({:ask, sender, text}, socket, channel, nick) do
    msg = "[from #{sender}] #{text}"
    addr = via(nick)

    case GenServer.call(addr, {:ask, msg}, :infinity) do
      {:error, _} -> :noop
      answer -> :gen_tcp.send(socket, "PRIVMSG #{channel} :#{answer}\r\n")
    end
  end

  defp reply(:noop, _socket, _channel, _nick), do: :ok

  defp via(nick) do
    {:via, Registry, {ElitaRegistry, Utils.Normalize.name(nick), %{kind: :native, folder: nil}}}
  end
end
