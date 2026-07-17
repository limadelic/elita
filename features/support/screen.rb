class Screen
  WIDTH = 80
  HEIGHT = 24
  def initialize(width = WIDTH, height = HEIGHT)
    @width = width
    @height = height
    @sgr = Sgr.new
    clear
  end

  def feed(bytes)
    return if bytes.nil? || bytes.empty?

    bytes.each_char { |char| process_char(char) }
  end

  def to_s
    @grid.map { |row| row.join.rstrip }.join("\n")
  end

  def include?(text)
    to_s.include?(text)
  end

  private

  def clear
    @grid = Array.new(@height) { Array.new(@width, ' ') }
    @cursor_x = 0
    @cursor_y = 0
    @escape_buffer = nil
    @sgr.reset
  end

  def process_char(char)
    handle_escape(char) || handle_control(char) ||
      handle_printable(char)
  end

  def handle_escape(char)
    char == "\e" ? (@escape_buffer = "\e") : false
  end

  def handle_control(char)
    return false unless "\r\n\t".include?(char)

    case char
    when "\r" then @cursor_x = 0
    when "\n" then advance_line
    when "\t" then handle_tab
    end
  end

  def handle_printable(char)
    @escape_buffer ? buffer_char(char) : write_char(char)
  end

  def buffer_char(char)
    @escape_buffer << char
    process_escape if escape_complete?
  end

  def handle_tab
    @cursor_x = ((@cursor_x + 8) / 8) * 8
    @cursor_x = @width - 1 if @cursor_x >= @width
  end

  def escape_complete?
    return false unless @escape_buffer && @escape_buffer.length >= 2

    check_complete
  end

  def check_complete
    case @escape_buffer[1]
    when '[' then @escape_buffer[-1].match?(/[A-Za-z]/)
    when ']' then osc_end?
    when /[(*+)]/ then @escape_buffer.length >= 3
    else @escape_buffer.length == 2
    end
  end

  def osc_end?
    @escape_buffer.include?("\x07") || @escape_buffer.end_with?("\e\\")
  end

  def process_escape
    seq = @escape_buffer
    @escape_buffer = nil
    return unless seq

    route_escape(seq)
  end

  def route_escape(seq)
    cursor_seq(seq) || edit_seq(seq)
  end

  def cursor_seq(seq)
    return handle_arrow_keys(seq) || handle_cursor_pos(seq)
  end

  def handle_arrow_keys(seq)
    keys = {
      'A' => :cursor_up, 'B' => :cursor_down,
      'C' => :cursor_right, 'D' => :cursor_left, 'G' => :cursor_to_col
    }
    return false unless seq =~ /\e\[([0-9]*)([A-DG])/

    count = $1.to_i
    key = $2
    send(keys[key], count)
  end

  def handle_cursor_pos(seq)
    return cursor_pos(1, 1) if seq =~ /\e\[H/
    return cursor_pos(1, 1) if seq =~ /\e\[f/
    return cursor_pos($1.to_i, $2.to_i) if seq =~ /\e\[([0-9]*);([0-9]*)H/
    return cursor_pos($1.to_i, $2.to_i) if seq =~ /\e\[([0-9]*);([0-9]*)f/

    false
  end

  def edit_seq(seq)
    case seq
    when /\e\[2J/ then clear
    when /\e\[K/ then clear_eol
    when /\e\[.*m$/ then @sgr.parse(seq)
    end
  end

  def cursor_up(n)
    @cursor_y = [[@cursor_y - (n > 0 ? n : 1), 0].max, @height - 1].min
  end

  def cursor_down(n)
    @cursor_y = [[@cursor_y + (n > 0 ? n : 1), @height - 1].min, 0].max
  end

  def cursor_right(n)
    @cursor_x = [[@cursor_x + (n > 0 ? n : 1), @width - 1].min, 0].max
  end

  def cursor_left(n)
    @cursor_x = [[@cursor_x - (n > 0 ? n : 1), 0].max, @width - 1].min
  end

  def cursor_to_col(col)
    @cursor_x = [col > 0 ? col - 1 : 0, @width - 1].min
  end

  def cursor_pos(row, col)
    @cursor_y = [row > 0 ? row - 1 : 0, @height - 1].min
    @cursor_x = [col > 0 ? col - 1 : 0, @width - 1].min
  end

  def clear_eol
    char = @sgr.fill_char
    (@width - 1).downto(@cursor_x) { |x| set_cell(x, @cursor_y, char) }
  end

  def write_char(char)
    char = @sgr.fill_char if char == ' ' && @sgr.active?
    set_cell(@cursor_x, @cursor_y, char)
    @cursor_x += 1
    @cursor_x = @width - 1 if @cursor_x >= @width
  end

  def wrap_line
    @cursor_x = 0
    advance_line
  end

  def advance_line
    @cursor_y = (@cursor_y + 1) % @height
    @cursor_x = 0
  end

  def set_cell(x, y, char)
    return if x < 0 || x >= @width || y < 0 || y >= @height

    @grid[y][x] = char
  end
end

module ScreenModule
  def screen
    @screen ||= Screen.new
    @screen.to_s
  end

  def snap
    lines = @screen.to_s.split("\n")
    lines.shift while lines.first&.empty?
    lines.pop while lines.last&.empty?
    lines.join("\n")
  end
end

World(ScreenModule)
