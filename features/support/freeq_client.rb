require 'socket'
require_relative 'freeq_sasl'

module FreeqClient
  include FreeqSasl

  CAPS = "sasl batch draft/multiline message-tags extended-join"

  def freeq_connect(name, host, port)
    socket = TCPSocket.new(host, port)
    setup(socket, name)
    sessions[name] = { socket: socket, name: name, type: :freeq }
    @current = name
  end

  def freeq_session?(name)
    sessions.dig(name, :type) == :freeq
  end

  def freeq_close(name)
    session = sessions[name]
    close_session(session) if session
    sessions.delete(name)
  end

  private

  def setup(socket, name)
    auth_caps(socket)
    finish_login(socket, name)
    write_join(socket)
  end

  def auth_caps(socket)
    write_line(socket, "CAP LS 302")
    read_line(socket, /CAP \* LS/)
    write_line(socket, "CAP REQ :#{CAPS}")
    read_line(socket, /ACK/)
  end

  def finish_login(socket, name)
    write_line(socket, "NICK #{name}")
    write_line(socket, "USER #{name} 0 * :#{name}")
    sasl_authenticate(socket, name)
    write_line(socket, "CAP END")
    welcome(socket, name)
  end

  def welcome(socket, name)
    read_line(socket, / 001 /)
    msgsig(socket, load_key(name).raw_public_key)
  end

  def net_read(socket)
    ready = IO.select([socket], nil, nil, 0.1)
    return "" unless ready

    read_socket(socket)
  end

  def read_socket(socket)
    socket.readpartial(4096)
  rescue EOFError
    ""
  end

  def write_join(socket)
    write_line(socket, "JOIN #the-lab")
    write_line(socket, "NAMES #the-lab")
    read_line(socket, / 366 \S+ #the-lab /)
  end

  def close_session(session)
    socket = session.dig(:socket)
    write_line(socket, "QUIT")
    socket.close
  end
end

World(FreeqClient)
