module Reap
  def reap_without_orphans
    @sessions ||= {}
    reap_sessions
    close_main_pty
    @sessions.clear
  end

  def reap_all_sessions
    @sessions ||= {}
    killed_any = reap_sessions
    kill_after_reap(killed_any)
    close_main_pty
    @sessions.clear
  end

  def reap_sessions
    killed = false
    @sessions.each do |_name, session|
      killed = true if close_session(session)
    end
    killed
  end

  def close_session(session)
    return false unless session&.[](:pid)

    kill_process(session[:pid])
    session[:reader]&.close
    session[:writer]&.close
    true
  end

  def close_main_pty
    safe_close(@reader)
    safe_close(@writer)
  end

  def safe_close(io)
    return unless io
    return if io.closed?

    io.close
  end
end
