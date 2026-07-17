class Sgr
  def initialize
    @bg_color = nil
  end

  def reset
    @bg_color = nil
  end

  def parse(seq)
    return unless seq =~ /\e\[.*m$/

    match = seq.match(/\e\[([^m]*)m/)
    return unless match

    params = match[1].split(';')
    params.each_with_index { |_, i| parse_param(params, i) }
  end

  def active?
    !@bg_color.nil?
  end

  def fill_char
    active? ? '█' : ' '
  end

  private

  def parse_param(params, i)
    param = params[i].to_i
    return if [0, 49].include?(param)

    return parse_bg(params, i) if param == 48
  end

  def parse_bg(params, i)
    return unless params[i + 1]

    case params[i + 1].to_i
    when 5 then handle_256color(params, i)
    when 2 then handle_rgb(params, i)
    end
  end

  def handle_256color(params, i)
    return unless params[i + 2]

    @bg_color = "256:#{params[i + 2]}"
  end

  def handle_rgb(params, i)
    return unless params[i + 4]

    r = params[i + 2]
    g = params[i + 3]
    b = params[i + 4]
    @bg_color = "rgb:#{r};#{g};#{b}"
  end
end
