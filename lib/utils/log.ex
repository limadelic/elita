defmodule Log do
  import Format
  import IO, only: [puts: 1]

  def q(prompt) do
    prompt[:contents]
    |> Kernel.||([])
    |> List.last()
    |> log()

    prompt
  end

  def a(result) do
    log(result)
    result
  end

  def t(name, args) do
    format(name, args)
    |> then(&pimp("🛠️: #{&1}", 196))
  end

  defp format("tell", %{"message" => msg, "recipient" => to}) do
    truncated =
      msg
      |> String.replace("\\n", "\n")
      |> truncate()

    "#{truncated} → #{to}"
  end

  defp format(name, args) do
    yaml(name, args)
  end

  def r(result) do
    formatted = yaml(result)
    pimp("🎯: #{formatted}", 226)
    result
  end

  def tell(msg) do
    pimp("📢: #{msg}", 226)
  end

  defp pimp(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end

  defp log(%{parts: [%{text: text}], role: "user"}) do
    pimp("🤔: #{text}", 82)
  end

  defp log([%{"text" => text}]) do
    pimp("✨: #{text}", 255)
  end

  defp log(_) do
    nil
  end
end
