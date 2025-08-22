defmodule Log do
  import Format
  import IO, only: [puts: 1]

  def q(text, name) do
    log("🤔", name, text)
  end

  def a(result, name \\ "user") do
    log("✨", name, result)
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
    pimp("🎯: #{yaml(result)}", 226)
    result
  end

  def tell(msg, name \\ "user") do
    pimp("📢 #{name}: #{msg}", 226)
  end

  defp pimp(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end

  defp log(emoji, name, %{parts: [%{text: text}], role: "user"}) do
    pimp("#{emoji} #{name}: #{text}", 82)
  end

  defp log(emoji, name, [%{"text" => text}]) do
    pimp("#{emoji} #{name}: #{text}", 255)
  end

  defp log(emoji, name, text) when is_binary(text) do
    pimp("#{emoji} #{name}: #{text}", 255)
  end

  defp log(emoji, name, result) do
    pimp("#{emoji} #{name}: #{inspect(result)}", 255)
  end
end
