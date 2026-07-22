module Snap
  def grab(tbl)
    timeout = limit
    snap_lines = snooze(timeout)
    golden_lines = golden(tbl)
    verified(golden_lines, snap_lines)
  end

  def golden(tbl)
    tbl.raw.map { |row| row[0].rstrip }
  end

  def verified(golden_lines, snap_lines)
    raise error(golden_lines, snap_lines) unless found?(golden_lines, snap_lines)
  end

  def error(golden_lines, snap_lines)
    snap_detail = snap_lines.each_with_index.map { |l, i| "  [#{i}] len=#{l.length}" }.join("\n")
    "Expected snap block (#{golden_lines.length} lines):\nActual snap (#{snap_lines.length} lines):\n#{snap_detail}"
  end

  def capture
    screen_render = @screen ? @screen.to_s : ""
    lines = screen_render.split("\n")
    crop(lines)
  end

  def crop(lines)
    crop_top(lines)
    crop_bottom(lines)
    lines
  end

  def crop_top(lines)
    lines.shift while top_empty?(lines)
  end

  def top_empty?(lines)
    first_line_empty?(lines) if lines.any?
  end

  def first_line_empty?(lines)
    lines.first&.empty?
  end

  def crop_bottom(lines)
    lines.pop while bottom_empty?(lines)
  end

  def bottom_empty?(lines)
    last_line_empty?(lines) if lines.any?
  end

  def last_line_empty?(lines)
    lines.last&.empty?
  end

  def snooze(timeout)
    current = capture
    sleep 3
    next_frame = capture

    return current if current == next_frame

    abide(timeout)
  end

  def abide(timeout)
    raise "Timeout waiting for screen settle" if Time.now > timeout

    snooze(timeout)
  end

  def found?(golden_lines, snap_lines)
    return true if golden_lines.empty?

    pin(snap_lines, golden_lines)
  end

  def pin(snap_lines, golden_lines)
    idx = position(snap_lines, golden_lines)
    idx != nil
  end

  def position(snap_lines, golden_lines)
    max_idx = snap_lines.length - golden_lines.length
    traverse(snap_lines, golden_lines, max_idx)
  end

  def traverse(snap_lines, golden_lines, max_idx)
    (0..max_idx).find { |i| fits?(snap_lines, golden_lines, i) }
  end

  def fits?(snap_lines, golden_lines, idx)
    block = snap_lines[idx, golden_lines.length]
    pare(block) == pare(golden_lines)
  end

  def pare(lines)
    lines.map { |l| l.rstrip }
  end

  def limit
    Time.now + 30
  end
end
