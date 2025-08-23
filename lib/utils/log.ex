defmodule Log do
  import Format, only: [yaml: 1]
  import IO, only: [puts: 1]
  import String, only: [contains?: 2, replace: 3]

  @colors %{
    green: 82,
    white: 255,
    blue: 33,
    yellow: 226,
    red: 196
  }

  def log(emoji, header, body, color) do
    formatted_body = yaml(body)
    color_code = @colors[color]
    puts("\e[38;5;#{color_code}m#{emoji} #{header}: #{formatted_body}\e[0m")
  end
end
