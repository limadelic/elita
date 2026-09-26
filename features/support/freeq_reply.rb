module FreeqReply
  def freeq_emit(name, command)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?

    net_write(session, line(command))
  end

  def freeq_collect(name)
    session = sessions[name]
    raise "No freeq session: #{name}" if session.nil?

    @heard = receive(session)
  end

  def freeq_quiet(name)
    heard = "#{@heard}#{freeq_collect(name)}"
    raise "Expected quiet, heard:\n#{heard}" if heard.match?(/ PRIVMSG #the-lab /)
  end

  private

  def line(text)
    return text.delete_prefix('/') if text.start_with?('/')

    "PRIVMSG #the-lab :#{text}"
  end

  def net_write(session, cmd)
    session[:socket].write("#{cmd}\r\n")
    session[:socket].flush
  end

  def receive(session)
    reply = ""
    limit = Time.now + 5
    loop do
      reply = gather_bytes(reply, session[:socket])
      return reply if replied?(reply, limit)
    end
  end

  def replied?(reply, limit)
    final?(reply) || Time.now > limit
  end

  def gather_bytes(accum, socket)
    chunk = read_bytes(socket)
    accum << chunk
  end

  def read_bytes(socket)
    net_read(socket)
  end

  def final?(data) = data.match?(/ (674|318|PRIVMSG) /)

  def dispatch_emit(prompt, input)
    freeq_session?(prompt) ? freeq_emit(prompt, input) : push(input)
  end

  def dispatch_collect(prompt)
    freeq_session?(prompt) ? freeq_collect(prompt) : hold(prompt)
  end
end

World(FreeqReply)
