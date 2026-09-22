defmodule Elita.Freeq do
  use GenServer

  import Keyword, only: [fetch!: 2]
  import String, only: [trim_trailing: 2]
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
    Elita.Freeq.Parser.parse(msg, nick, channel)
    |> maybe_reply(socket, channel, nick)

    {:noreply, state}
  end

  defp handle(_msg, state) do
    {:noreply, state}
  end

  defp maybe_reply({:ask, sender, text}, socket, channel, nick) do
    msg = "[from #{sender}] #{text}"
    reply(socket, channel, nick, msg)
  end

  defp maybe_reply(:noop, _socket, _channel, _nick), do: :ok

  defp reply(socket, channel, nick, msg) do
    case GenServer.call(via(nick), {:ask, msg}, :infinity) do
      {:error, _} -> :noop
      answer -> :gen_tcp.send(socket, "PRIVMSG #{channel} :#{answer}\r\n")
    end
  end

  defp via(nick) do
    normalized = Utils.Normalize.name(nick)
    {:via, Registry, {ElitaRegistry, normalized, %{kind: :native, folder: nil}}}
  end
end
