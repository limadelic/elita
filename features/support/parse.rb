module Parse
  PATTERNS = [
    /^[\p{So}🀀-🿿][\s]*[a-zA-Z🀀-🿿]/,
    /^✏️\s+\w+.*=/,
    /^\w+>\s+[\p{So}🀀-🿿]/,
    /^\w+>$/
  ].freeze
  def normalize(transcript)
    tx = encode(transcript)
    tx = ansi(tx)
    tx = polish(tx)
    lines = lines(tx)
    fold(lines)
  end

  def encode(text)
    text.dup.force_encoding("UTF-8") rescue text
  end

  def ansi(text)
    text.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
  end

  def lines(text)
    lines = text.split("\n").map { |l| encode(l.strip) }
    empty(lines)
  end

  def empty(lines)
    lines.reject(&:empty?)
  end

  def fold(lines)
    lines.each_with_object([]) { |line, result| crease(line, result) }
  end

  def crease(line, result)
    is_log = log?(line)
    splice(line, result, is_log)
  end

  def log?(line)
    PATTERNS.any? { |p| matching?(line, p) }
  end

  def matching?(line, pattern)
    line.match?(pattern) rescue false
  end

  def splice(line, result, is_log)
    is_log ? fresh(line, result) : fuse(line, result)
  end

  def fresh(line, result)
    result << line
  end

  def fuse(line, result)
    result[-1] << " " << line unless result.empty?
  end

  def polish(text)
    text.gsub("\u{FE0F}", "")
  end
end
