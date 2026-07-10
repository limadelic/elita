class Screen
  WIDTH = 80
  HEIGHT = 24

  def initialize(width = WIDTH, height = HEIGHT)
    @width = width
    @height = height
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
    return false unless @escape_buffer
    return false if @escape_buffer.length < 2

    csi_escape? ? csi_complete? : two_char?
  end

  def csi_escape?
    @escape_buffer[1] == '['
  end

  def csi_complete?
    @escape_buffer[-1].match?(/[A-Za-z]/)
  end

  def two_char?
    @escape_buffer.length == 2
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
    case seq
    when /\e\[([0-9]*)A/ then cursor_up($1.to_i)
    when /\e\[([0-9]*)B/ then cursor_down($1.to_i)
    when /\e\[([0-9]*)C/ then cursor_right($1.to_i)
    when /\e\[([0-9]*)D/ then cursor_left($1.to_i)
    when /\e\[([0-9]*);([0-9]*)H/,
         /\e\[([0-9]*);([0-9]*)f/ then cursor_pos($1.to_i, $2.to_i)
    else
      false
    end
  end

  def edit_seq(seq)
    case seq
    when /\e\[2J/ then clear
    when /\e\[K/ then clear_eol
    end
  end

  def cursor_up(n)
    n = n > 0 ? n : 1
    @cursor_y = [@cursor_y - n, 0].max
  end

  def cursor_down(n)
    n = n > 0 ? n : 1
    @cursor_y = [@cursor_y + n, @height - 1].min
  end

  def cursor_right(n)
    n = n > 0 ? n : 1
    @cursor_x = [@cursor_x + n, @width - 1].min
  end

  def cursor_left(n)
    n = n > 0 ? n : 1
    @cursor_x = [@cursor_x - n, 0].max
  end

  def cursor_pos(row, col)
    row = row > 0 ? row : 1
    col = col > 0 ? col : 1
    @cursor_y = [row - 1, @height - 1].min
    @cursor_x = [col - 1, @width - 1].min
  end

  def clear_eol
    (@width - 1).downto(@cursor_x) { |x| set_cell(x, @cursor_y, ' ') }
  end

  def write_char(char)
    set_cell(@cursor_x, @cursor_y, char)
    @cursor_x += 1
    wrap_line if @cursor_x >= @width
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
end

World(ScreenModule)
