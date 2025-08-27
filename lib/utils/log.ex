defmodule Log do
  import Utils.Yaml, only: [yaml: 1]
  import String, only: [contains?: 2]
  import IO, only: [puts: 1]

  @colors %{
    green: 82,
    white: 255,
    blue: 33,
    yellow: 226,
    red: 196
  }

  def log(emoji, head, neck, body, color) do
    body = yaml(body)
    neck = neck <> (contains?(body, "\n") && "\n" || "")
    puts("\e[38;5;#{@colors[color]}m#{emoji} #{head}#{neck}#{body}\e[0m")
  end
end
