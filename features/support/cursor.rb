module Cursor
  def arrow(seq)
    return false unless seq =~ /\e\[([0-9]*)([A-D])/

    n = $1.to_i
    dir = $2
    guide(dir, n)
  end

  def place(seq)
    return false unless seq =~ /\e\[([0-9]*);([0-9]*)[Hf]/

    aim($1.to_i, $2.to_i)
  end

  private

  def guide(dir, n)
    count = normalize(n)
    arrows[dir]&.call(count)
    true
  end

  def normalize(n)
    n > 0 ? n : 1
  end

  def arrows
    {
      "A" => method(:up),
      "B" => method(:down),
      "C" => method(:right),
      "D" => method(:left)
    }
  end

  def up(n)
    @cursor_y = [@cursor_y - n, 0].max
  end

  def down(n)
    @cursor_y = [@cursor_y + n, @height - 1].min
  end

  def right(n)
    @cursor_x = [@cursor_x + n, @width - 1].min
  end

  def left(n)
    @cursor_x = [@cursor_x - n, 0].max
  end

  def aim(row, col)
    @cursor_y = pos(normalize(row), @height)
    @cursor_x = pos(normalize(col), @width)
  end

  def pos(val, limit)
    [val - 1, limit - 1].min
  end
end
