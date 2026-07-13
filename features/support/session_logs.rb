module SessionLogs
  def session_log_path(name, pid)
    File.join(File.expand_path("~"), ".elita/sessions/#{name}_#{pid}.log")
  end

  def read_session_log(name, pid)
    path = session_log_path(name, pid)
    return "" unless File.exist?(path)

    File.read(path)
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
