module Status
  def closed?
    timeout = Time.now + 2
    settle(timeout)
  end

  def settle(timeout)
    orbit(timeout)
    gone?
  end

  def orbit(timeout)
    until halt?(timeout)
      sleep 0.05
    end
  end

  def halt?(timeout)
    ready? || expired?(timeout)
  end

  def ready?
    spent? || dead?
  end

  def expired?(timeout)
    Time.now > timeout
  end

  def gone?
    spent? || dead?
  end

  private

  def spent?
    return false unless @reader

    probe
  end

  def probe
    @drain_thread ? hung? : bare?
  end

  def hung?
    !@drain_thread.alive?
  end

  def bare?
    ready = IO.select([@reader], nil, nil, 0.1)
    return false unless ready

    sniff
  end

  def sniff
    @reader.readpartial(1)
    false
  rescue EOFError, Errno::EIO
    true
  end

  def dead?
    return false unless @pid

    wait
  end

  def wait
    Process.wait(@pid, Process::WNOHANG)
    true
  rescue Errno::ECHILD
    true
  end
end
