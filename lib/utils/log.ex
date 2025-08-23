defmodule Log do
  import Format, only: [yaml: 1]
  import IO, only: [puts: 1]

  @colors %{
    green: 82,
    white: 255,
    blue: 33,
    yellow: 226,
    red: 196
  }

  def log(emoji, header, body, color) do
    puts("\e[38;5;#{@colors[color]}m#{emoji} #{header}: #{yaml(body)}\e[0m")
  end
end
