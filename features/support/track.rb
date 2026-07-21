module Track
  def track_pid(pid)
    @tracked_pids ||= []
    @tracked_pids << pid if pid && pid > 0
  end

  def kill_tracked_pids
    return if @tracked_pids.nil? || @tracked_pids.empty?

    send_term_signals
    wait_graceful
    send_kill_signals
    @tracked_pids.clear
  end

  def send_term_signals
    @tracked_pids.each { |pid| signal_pid(pid, "TERM") }
  end

  def send_kill_signals
    @tracked_pids.each { |pid| signal_pid(pid, "KILL") }
  end

  def signal_pid(pid, sig)
    return unless pid_alive?(pid)

    Process.kill(sig, pid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  def pid_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end

  def living_pids
    @tracked_pids.select { |pid| pid_alive?(pid) }
  end

  def wait_graceful
    deadline = Time.now + 2.0
    loop do
      remaining = living_pids
      break if remaining.empty? || Time.now > deadline

      sleep 0.05
    end
  end
end
