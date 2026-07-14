module SessionLogs
  def session_log_path(name, pid)
    File.join(File.expand_path("~"), ".elita/sessions/#{name}_#{pid}.log")
  end

  def read_session_log(name, pid)
    # Find the most recently modified name_*.log file
    # (the Erlang VM's PID differs from the shell's PID)
    dir = File.join(File.expand_path("~"), ".elita/sessions")
    return "" unless Dir.exist?(dir)

    logs = Dir.glob("#{dir}/#{name}_*.log").sort_by { |f| File.mtime(f) }
    return "" if logs.empty?

    File.read(logs.last)
  end

  def verify_session_markers(rows, name, pid)
    log_content = read_session_log(name, pid)
    raise "Session log not found for #{name}_#{pid}" if log_content.empty?

    check_marker_rows(rows, log_content)
  end

  def check_marker_rows(rows, log_content)
    rows.each { |row| check_single_marker(row, log_content) }
  end

  def check_single_marker(row, log_content)
    prefix = row[0].strip
    text = row[1].strip.downcase
    return if log_content.include?(prefix) && log_content.downcase.include?(text)

    raise "Expected '#{prefix}' and '#{text}' in session log:\n#{log_content}"
  end
end
