require 'socket'

module Freeq
  def freeq_connect(name, host, port)
    socket = TCPSocket.new(host, port)
    setup(socket, name)
    sessions[name] = { socket: socket, buffer: "", name: name, type: :freeq }
    @current = name
  end

  def freeq_session?(name)
    sessions.dig(name, :type) == :freeq
  end

  def freeq_emit(name, command)
    session = sessions[name] || raise("No freeq session: #{name}")
    cmd = strip_slash(command)
    emit_cmd(session, cmd)
  end

  def strip_slash(command)
    command.start_with?('/') ? command[1..-1] : command
  end

  def freeq_collect(name, timeout_sec = 5)
    session = sessions[name]
    raise "No freeq session: #{name}" unless session

    collect_response(session, timeout_sec)
  end

  def freeq_close(name)
    session = sessions[name]
    close_session(session)
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
    deadline = Time.now + 5
    loop { return if code_found?(socket, code, deadline) }
  end

  def code_found?(socket, code, deadline)
    available?(deadline) && code?(socket, code)
  end

  def available?(deadline)
    Time.now < deadline
  end

  def code?(socket, code)
    ready = IO.select([socket], nil, nil, 0.1)
    ready && socket.readpartial(4096).include?(code)
  end

  def emit_cmd(session, cmd)
    session[:buffer] = ""
    session[:socket].write("#{cmd}\r\n")
    session[:socket].flush
  end

  def collect_response(session, timeout_sec)
    deadline = Time.now + timeout_sec
    response = ""
    loop do
      break if Time.now > deadline

      response = read_chunk(session, response, deadline)
    end
    response
  end

  def read_chunk(session, response, deadline)
    return response if should_skip?(session, deadline)

    accumulate(session, response)
  end

  def should_skip?(session, deadline)
    expired?(deadline) || !socket_ready?(session)
  end

  def expired?(deadline)
    Time.now > deadline
  end

  def socket_ready?(session)
    IO.select([session[:socket]], nil, nil, 0.1)
  end

  def accumulate(session, response)
    chunk = session[:socket].readpartial(4096)
    response << chunk
    session[:buffer] << chunk
    response
  end

  def close_session(session)
    session.dig(:socket)&.close
  end
end

World(Freeq)
