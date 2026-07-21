require_relative "cursor"
require_relative "escape"

class Screen
  include Cursor
  include Escape

  WIDTH = 80
  HEIGHT = 24

  def initialize(width = WIDTH, height = HEIGHT)
    @width = width
    @height = height
    clear
  end

  def absorb(bytes)
    return unless content?(bytes)

    bytes.each_char { |char| process(char) }
  end

  def content?(bytes)
    bytes.nil? ? false : bytes.length.positive?
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

  def process(char)
    return spark if char == "\e"

    handle(char)
  end

  def handle(char)
    buffering? ? buffer(char) : direct(char)
  end

  def direct(char)
    control?(char) ? execute(char) : write(char)
  end

  def buffering?
    !@escape_buffer.nil?
  end

  def control?(char)
    "\r\n\t".include?(char)
  end

  def execute(char)
    route[char]&.call
  end

  def route
    {
      "\r" => -> { @cursor_x = 0 },
      "\n" => method(:scroll),
      "\t" => method(:tab)
    }
  end

  def tab
    tab_stop = ((@cursor_x + 8) / 8) * 8
    @cursor_x = [tab_stop, @width - 1].min
  end

  def write(char)
    mark(@cursor_x, @cursor_y, char)
    @cursor_x += 1
    wrap if @cursor_x >= @width
  end

  def wrap
    @cursor_x = 0
    scroll
  end

  def scroll
    @cursor_y = (@cursor_y + 1) % @height
    @cursor_x = 0
  end

  def mark(x, y, char)
    return if outside?(x, y)

    @grid[y][x] = char
  end

  def outside?(x, y)
    xbound?(x) || ybound?(y)
  end

  def xbound?(x)
    x < 0 || x >= @width
  end

  def ybound?(y)
    y < 0 || y >= @height
  end

  def sweep
    (@width - 1).downto(@cursor_x) { |x| mark(x, @cursor_y, ' ') }
  end
end

module ScreenModule
  def screen
    @screen ||= Screen.new
    @screen.to_s
  end
end

World(ScreenModule)
