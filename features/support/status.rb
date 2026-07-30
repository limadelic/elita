module Status
  def closed?
    timeout = Time.now + 2
    linger(timeout)
  end

  def linger(timeout)
    loop do
      return true if primed?(timeout)

      sleep 0.05
    end
  end

  def primed?(timeout)
    spied? || failed?(timeout)
  end

  def failed?(timeout)
    fled? || past?(timeout)
  end

  def past?(timeout)
    Time.now > timeout
  end

  private

  def spied?
    return false unless @reader

    audit
  end

  def audit
    @drain_thread ? stalled? : drained?
  end

  def stalled?
    !@drain_thread.alive?
  end

  def drained?
    ready = IO.select([@reader], nil, nil, 0.1)
    return false unless ready

    peek
  end

  def peek
    @reader.readpartial(1)
    false
  rescue EOFError, Errno::EIO
    true
  end

  def fled?
    return false unless @pid

    dead?
  end

  def dead?
    Process.wait(@pid, Process::WNOHANG)
    true
  rescue Errno::ECHILD
    true
  end
end
