module SessionLogs
  def trail(name, pid)
    File.join(File.expand_path("~"), ".elita/sessions/#{name}_#{pid}.log")
  end

  def pull(name, _pid)
    dir = File.join(File.expand_path("~"), ".elita/sessions")
    return "" unless Dir.exist?(dir)

    logs = merge(dir, name)
    pluck(logs)
  end

  def merge(dir, name)
    Dir.glob("#{dir}/#{name}_*.log").sort_by { |f| File.mtime(f) }
  end

  def pluck(logs)
    return "" if logs.empty?

    File.read(logs.last)
  end

  def attest(rows, name, pid)
    log_content = pull(name, pid)
    raise "Session log not found for #{name}_#{pid}" if log_content.empty?

    detail(rows, log_content)
  end

  def detail(rows, log_content)
    rows.each { |row| poke(row, log_content) }
  end

  def poke(row, log_content)
    prefix = row[0].strip
    text = row[1].strip.downcase
    logged?(log_content, prefix, text) || gripe(prefix, text, log_content)
  end

  def logged?(log_content, prefix, text)
    log_content.include?(prefix) && log_content.downcase.include?(text)
  end

  def gripe(prefix, text, log_content)
    raise "Expected '#{prefix}' and '#{text}' in session log:\n#{log_content}"
  end
end
