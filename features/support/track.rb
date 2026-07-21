module Track
  def watch(pid)
    @tracked_pids ||= []
    enlist(pid)
  end

  def enlist(pid)
    return unless positive?(pid)

    @tracked_pids << pid
  end

  def positive?(pid)
    pid&.positive?
  end

  def terminate
    return if none?

    cease
    breathe
    finish
    @tracked_pids.clear
  end

  def none?
    @tracked_pids.nil? || @tracked_pids.empty?
  end

  def cease
    @tracked_pids.each { |pid| notify(pid, "TERM") }
  end

  def finish
    @tracked_pids.each { |pid| notify(pid, "KILL") }
  end

  def notify(pid, sig)
    transmit(pid, sig) if vital?(pid)
  end

  def transmit(pid, sig)
    Process.kill(sig, pid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  def vital?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end

  def roster
    @tracked_pids.select { |pid| vital?(pid) }
  end

  def breathe
    deadline = Time.now + 2.0
    until over?(deadline)
      sleep 0.05
    end
  end

  def over?(deadline)
    roster.empty? || Time.now > deadline
  end
end
