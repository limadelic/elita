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

    rows.each do |row|
      prefix = row[0].strip
      text = row[1].strip.downcase

      unless log_content.include?(prefix) && log_content.downcase.include?(text)
        raise "Expected '#{prefix}' and '#{text}' in session log:\n#{log_content}"
      end
    end
  end
end
