module Reap
  def bundle
    @sessions ||= {}
    reap
    shut
    purge_threads
    @sessions.clear
  end

  def purge_threads
    @sessions.each { |_name, session| slain(session) }
    slain_current
  end

  def slain(session)
    thread = session&.[](:drain_thread)
    kill_thread(thread)
  end

  def slain_current
    zap(@drain_thread)
  end

  def zap(thread)
    thread.kill
  rescue StandardError
    nil
  end

  def kill_thread(thread)
    zap(thread)
  end

  def harvest
    @sessions ||= {}
    killed_any = reap
    cleanse(killed_any)
    shut
    purge_threads
    @sessions.clear
  end

  def reap
    killed = false
    @sessions.each { |_name, session| killed = tally(killed, session) }
    killed
  end

  def tally(killed, session)
    killed || reave(session)
  end

  def reave(session)
    return false if bare?(session)

    slay(session[:pid])
    cork(session[:reader])
    cork(session[:writer])
    true
  end

  def bare?(session)
    !session&.[](:pid)
  end

  def shut
    cork(@reader)
    cork(@writer)
  end

  def cork(io)
    return unless io

    shutter(io)
  end

  def shutter(io)
    return if io.closed?

    io.close
  end
end
