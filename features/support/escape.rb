module Escape
  def buffer(char)
    @escape_buffer << char
    run if ready?
  end

  def ready?
    @escape_buffer && @escape_buffer.length >= 2
  end

  def done?
    csi? ? closed? : pair?
  end

  def csi?
    @escape_buffer[1] == '['
  end

  def closed?
    @escape_buffer[-1].match?(/[A-Za-z]/)
  end

  def pair?
    @escape_buffer.length == 2
  end

  def run
    s = @escape_buffer
    @escape_buffer = nil
    return unless s

    route(s)
  end

  def route(s)
    seq(s) || edit(s)
  end

  def edit(s)
    exec(s) if s =~ /\e\[(2J|K)/
  end

  def exec(s)
    s =~ /2J/ ? clear : erase
  end
end
