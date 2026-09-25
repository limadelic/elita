module FreeqReply
  def freeq_emit(name, command)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?

    net_write(session, command.sub(/\A\//, ''))
  end

  def freeq_collect(name)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?

    receive(session)
  end

  private

  def net_write(session, cmd)
    session[:socket].write("#{cmd}\r\n")
    session[:socket].flush
  end

  def receive(session)
    reply = ""
    loop do
      reply = gather_bytes(reply, session[:socket])
      return reply if final?(reply)
    end
  end

  def gather_bytes(accum, socket)
    chunk = read_bytes(socket)
    accum << chunk
  end

  def read_bytes(socket)
    net_read(socket)
  end

  def final?(data)
    data.include?(" 366 ") || data.include?(" 318 ")
  end

  def dispatch_emit(prompt, input)
    freeq_session?(prompt) ? freeq_emit(prompt, input) : push(input)
  end

  def dispatch_collect(prompt)
    freeq_session?(prompt) ? freeq_collect(prompt) : hold(prompt)
  end
end

World(FreeqReply)
