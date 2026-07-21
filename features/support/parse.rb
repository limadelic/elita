module Parse
  def normalize(transcript)
    tx = dupe(transcript)
    tx = scrub(tx)
    tx = clean(tx)
    lines = rows(tx)
    fold(lines)
  end

  def dupe(transcript)
    transcript.dup.force_encoding("UTF-8") rescue transcript
  end

  def scrub(tx)
    tx.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
  end

  def rows(tx)
    encoded = tx.split("\n").map { |l| encode(l.strip) }
    filter(encoded)
  end

  def filter(encoded)
    encoded.reject(&:empty?)
  end

  def fold(lines)
    lines.each_with_object([]) { |line, result| crease(line, result) }
  end

  def crease(line, result)
    is_log = log?(line)
    splice(line, result, is_log)
  end
end
