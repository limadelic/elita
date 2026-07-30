module Kill
  def slay(pid)
    return unless pid

    grace(pid)
  end

  def grace(pid)
    pgid = Process.getpgid(pid)
    Process.kill("TERM", -pgid)
    dwell(pgid)
    force(pgid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  def force(pgid)
    Process.kill("KILL", -pgid) if alive?(pgid)
  end

  def dwell(pgid)
    10.times do
      return true unless alive?(pgid)

      sleep 0.2
    end
    false
  end

  def alive?(pgid)
    Process.kill(0, -pgid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def recede(pid)
    Process.wait(pid, Process::WNOHANG)
  rescue Errno::ESRCH
    nil
  end

  def cleanse(killed_any)
    killed_any ? scavenge : purge
  end

  def purge
    slay(@pid) if @pid
    scavenge
  end

  def expunge
    os = orphans
    soften(os, 2)
  end

  def scavenge
    os = orphans
    cull(os, "TERM")
    sleep 0.1
    cull(os, "KILL")
  end

  def soften(pids, timeout_secs)
    alert(pids)
    bide(timeout_secs)
    cull(pids, "KILL")
  end

  def alert(pids)
    pids.each { |p| signal(p, "TERM") }
  end

  def signal(pid_str, sig)
    Process.kill(sig, pid_str.to_i) rescue Errno::ESRCH
  end

  def bide(timeout_secs)
    timeout_secs.times do
      remaining = orphans
      return if remaining.empty?

      sleep 1
    end
  end

  def orphans
    run_id = ENV["ELITA_RUN"]
    return [] unless run_id

    cmd = "ps eww | grep 'script -q /dev/null' | grep ELITA_RUN=#{run_id} | awk '{print $1}'"
    `#{cmd}`.strip.split("\n").compact
  end

  def cull(pids, sig)
    pids.each { |p| term(p, sig) }
  end

  def term(str, sig)
    pid = str.to_i
    smite(pid, sig)
  end

  def smite(pid, sig)
    return if pid.zero?

    flare(pid, sig)
  end

  def flare(pid, sig)
    Process.kill(sig, pid) rescue Errno::ESRCH
  end
end
