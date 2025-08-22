defmodule Color do
  import IO, only: [puts: 1]

  def puts(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end
end