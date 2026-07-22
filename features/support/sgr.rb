class Sgr
  def initialize
    @bg_color = nil
  end

  def reset
    @bg_color = nil
  end

  def parse(seq)
    extract_and_process(seq) if valid?(seq)
  end

  def valid?(seq)
    seq =~ /\e\[.*m$/
  end

  def extract_and_process(seq)
    match = seq.match(/\e\[([^m]*)m/)
    process_params(match[1].split(';')) if match
  end

  def process_params(params)
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
    handle_param(param, params, i)
  end

  def handle_param(param, params, i)
    purge(param)
    route_bg(param, params, i)
  end

  def purge(param)
    clear_on_zero(param)
    clear_on_forty_nine(param)
  end

  def clear_on_zero(param)
    @bg_color = nil if param == 0
  end

  def clear_on_forty_nine(param)
    @bg_color = nil if param == 49
  end

  def route_bg(param, params, i)
    parse_bg(params, i) if param == 48
  end

  def parse_bg(params, i)
    next_param = params[i + 1]
    return unless next_param

    dispatch(params, i, next_param.to_i)
  end

  def dispatch(params, i, mode)
    indexed_if_mode(params, i, mode)
    rgb_if_mode(params, i, mode)
  end

  def indexed_if_mode(params, i, mode)
    indexed(params, i) if mode == 5
  end

  def rgb_if_mode(params, i, mode)
    rgb(params, i) if mode == 2
  end

  def indexed(params, i)
    return unless params[i + 2]

    @bg_color = "256:#{params[i + 2]}"
  end

  def rgb(params, i)
    return unless params[i + 4]

    r = params[i + 2]
    g = params[i + 3]
    b = params[i + 4]
    @bg_color = "rgb:#{r};#{g};#{b}"
  end
end
