defmodule Log do
  import IO, only: [puts: 1]
  import String, only: [contains?: 2]
  import Utils.Yaml, only: [yaml: 1]

  @colors %{
    green: 82,
    white: 255,
    blue: 33,
    yellow: 226,
    red: 196
  }

  def log(emoji, head, neck, body, color) do
    body = yaml(body)
    neck = neck <> eol(body)
    puts("\e[38;5;#{@colors[color]}m#{emoji} #{head}#{neck}#{body}\e[0m")
  end

  defp eol(body) do
    body |> has_newline() |> eol_char()
  end

  defp has_newline(body) do
    contains?(body, "\n")
  end

  defp eol_char(true), do: "\n"
  defp eol_char(false), do: ""
end
