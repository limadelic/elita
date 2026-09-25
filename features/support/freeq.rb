require 'socket'

module Freeq
  def freeq_connect(name, host, port)
    socket = TCPSocket.new(host, port)
    setup(socket, name)
    sessions[name] = { socket: socket, name: name, type: :freeq }
    @current = name
  end

  def freeq_session?(name)
    sessions.dig(name, :type) == :freeq
  end

  def freeq_emit(name, command)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?
    emit_cmd(session, strip_slash(command))
  end

  def strip_slash(command)
    command.start_with?('/') ? command[1..-1] : command
  end

  def freeq_collect(name)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?
    read_reply(session)
  end

  def freeq_close(name)
    session = sessions[name]
    close_session(session) if session
    sessions.delete(name)
  end

  private

  def setup(socket, name)
    caps(socket)
    register(socket, name)
    join(socket)
  end

  def caps(socket)
    socket.write("CAP REQ :batch draft/multiline message-tags extended-join\r\n")
    socket.write("CAP END\r\n")
    socket.flush
  end

  def register(socket, name)
    socket.write("NICK #{name}\r\nUSER #{name} 0 * :#{name}\r\n")
    socket.flush
    read_until_code(socket, '001')
  end

  def join(socket)
    socket.write("JOIN #the-lab\r\n")
    socket.flush
    read_until_code(socket, '366')
  end

  def read_until_code(socket, code)
    data = ""
    loop do
      data = gather(socket, data)
      return if data.include?(" #{code} ")
    end
  end

  def gather(socket, accum)
    chunk = grab(socket)
    accum << chunk
  end

  def grab(socket)
    result = IO.select([socket], nil, nil, 0.1)
    return "" if result.nil?

    socket.readpartial(4096)
  rescue EOFError
    ""
  end

  def emit_cmd(session, cmd)
    session[:socket].write("#{cmd}\r\n")
    session[:socket].flush
  end

  def read_reply(session)
    reply = ""
    loop do
      chunk = grab(session[:socket])
      reply << chunk
      return reply if ended?(reply)
    end
  end

  def ended?(data)
    data.include?(" 366 ") || data.include?(" 318 ")
  end

  def close_session(session)
    session.dig(:socket)&.close
  end
end

World(Freeq)
