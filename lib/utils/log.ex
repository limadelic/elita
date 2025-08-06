defmodule Log do
  import IO, only: [puts: 1]

  def q(prompt) do
    log(List.last(prompt[:contents] || []))
    prompt
  end

  def a(result) do
    log(result)
    result
  end

  def t(name, args) do
    puts("T: #{name}(#{inspect(args)})")
  end

  def r(result) do
    puts("→ #{inspect(result)}")
    result
  end

  defp log(%{parts: [%{text: text}], role: "user"}) do
    puts(text)
  end

  defp log([%{"text" => text}]) do
    puts(text)
  end

  defp log(_) do
    nil
  end

end
