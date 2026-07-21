module Cursor
  def seq(s)
    move(s) || position(s)
  end

  def move(s)
    s =~ /\e\[([0-9]*)([A-D])/ ? arrow($1.to_i, $2) : false
  end

  def arrow(amount, direction)
    handlers = {
      "A" => method(:up),
      "B" => method(:down),
      "C" => method(:right),
      "D" => method(:left)
    }
    handlers[direction]&.call(amount)
  end

  def position(s)
    s =~ /\e\[([0-9]*);([0-9]*)[Hf]/ ? locate($1.to_i, $2.to_i) : false
  end

  def up(n)
    n = n > 0 ? n : 1
    @cursor_y = [@cursor_y - n, 0].max
  end

  def down(n)
    n = n > 0 ? n : 1
    @cursor_y = [@cursor_y + n, @height - 1].min
  end

  def right(n)
    n = n > 0 ? n : 1
    @cursor_x = [@cursor_x + n, @width - 1].min
  end

  def left(n)
    n = n > 0 ? n : 1
    @cursor_x = [@cursor_x - n, 0].max
  end

  def locate(row, col)
    row = [row, 1].max
    col = [col, 1].max
    @cursor_y = [row - 1, @height - 1].min
    @cursor_x = [col - 1, @width - 1].min
  end
end
