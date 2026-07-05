defmodule Color do
  import Kernel
  import IO, only: [puts: 1]

  def puts(text, code) do
    puts("\e[38;5;" <> to_string(code) <> "m" <> text <> "\e[0m")
  end
end
