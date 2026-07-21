module Kill
  def kill_process(pid)
    return unless pid

    kill_process_graceful(pid)
  end

  def kill_process_graceful(pid)
    pgid = Process.getpgid(pid)
    Process.kill("TERM", -pgid)
    wait_for_graceful_exit(pgid)
    Process.kill("KILL", -pgid) if still_alive?(pgid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  def wait_for_graceful_exit(pgid)
    10.times do
      return true unless still_alive?(pgid)

      sleep 0.2
    end
    false
  end

  def still_alive?(pgid)
    Process.kill(0, -pgid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def wait_process_end(pid)
    Process.wait(pid, Process::WNOHANG)
  rescue Errno::ESRCH
    nil
  end

  def kill_after_reap(killed_any)
    killed_any ? kill_orphaned_scripts : try_kill_main_pid
  end

  def try_kill_main_pid
    kill_process(@pid) if @pid
    kill_orphaned_scripts
  end

  def kill_orphaned_scripts_gracefully
    orphans = find_script_orphans
    terminate_gracefully(orphans, 2)
  end

  def kill_orphaned_scripts
    orphans = find_script_orphans
    terminate_pids(orphans, "TERM")
    sleep 0.1
    terminate_pids(orphans, "KILL")
  end

  def terminate_gracefully(pids, timeout_secs)
    pids.each { |p| Process.kill("TERM", p.to_i) rescue Errno::ESRCH }
    timeout_secs.times do
      remaining = find_script_orphans
      return if remaining.empty?

      sleep 1
    end
    terminate_pids(pids, "KILL")
  end

  def find_script_orphans
    run_id = ENV["ELITA_RUN"]
    return [] unless run_id

    cmd = "ps eww | grep 'script -q /dev/null' | grep ELITA_RUN=#{run_id} | awk '{print $1}'"
    `#{cmd}`.strip.split("\n").compact
  end

  def terminate_pids(pids, signal)
    pids.each do |pid_str|
      pid = pid_str.to_i
      next if pid.zero?

      Process.kill(signal, pid) rescue Errno::ESRCH
    end
  end
end
