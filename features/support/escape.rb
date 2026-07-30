module Escape
  def spark
    @escape_buffer = "\e"
  end

  def buffer(char)
    @escape_buffer << char
    run if ready?
  end

  private

  def ready?
    exist? && valid?
  end

  def valid?
    sufficient? && closed?
  end

  def exist?
    !@escape_buffer.nil?
  end

  def sufficient?
    @escape_buffer.length >= 2
  end

  def closed?
    csi? ? letter? : two?
  end

  def csi?
    @escape_buffer[1] == '['
  end

  def letter?
    @escape_buffer[-1].match?(/[A-Za-z]/)
  end

  def two?
    @escape_buffer.length == 2
  end

  def run
    seq = @escape_buffer
    @escape_buffer = nil
    dispatch(seq) if seq
  end

  def dispatch(seq)
    arrow(seq) || fallback(seq)
  end

  def fallback(seq)
    place(seq) || wipe(seq)
  end

  def wipe(seq)
    edit?(seq) ? exec(seq) : false
  end

  def exec(seq)
    cleared?(seq) ? clear : sweep
    true
  end

  def edit?(seq)
    seq =~ /\e\[(2J|K)/
  end

  def cleared?(seq)
    seq =~ /2J/
  end
end
