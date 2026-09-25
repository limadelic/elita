require 'socket'
module FreeqClient
  CAPS = "CAP REQ :batch draft/multiline message-tags extended-join"
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
    write_capabilities(socket)
    write_logon(socket, name)
    write_join(socket)
  end

  def write_capabilities(socket)
    socket.write("#{CAPS}\r\n")
    socket.write("CAP END\r\n")
    socket.flush
  end

  def write_logon(socket, name)
    socket.write("NICK #{name}\r\nUSER #{name} 0 * :#{name}\r\n")
    socket.flush
    wait_for_code(socket, '001')
  end

  def write_join(socket)
    socket.write("JOIN #the-lab\r\n")
    socket.flush
    wait_for_code(socket, '366')
  end

  def wait_for_code(socket, code)
    data = ""
    loop do
      data = accumulate(socket, data)
      return if data.include?(" #{code} ")
    end
  end

  def accumulate(socket, accum)
    chunk = net_read(socket)
    accum << chunk
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

  def close_session(session)
    socket = session.dig(:socket)
    socket.write("QUIT\r\n")
    socket.flush
    socket.close
  end
end

World(FreeqClient)
