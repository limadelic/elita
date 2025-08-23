defmodule Log do
  import Format
  import IO, only: [puts: 1]
  import String, only: [contains?: 2, replace: 3]

  def q(text, name) do
    log("🤔", name, text, 82)
  end

  def a(result, name) do
    log("✨", name, result, 255)
    result
  end

  def t(%{"name" => tool, "args" => args}) do
    pimp("🛠️ #{tool}:#{yaml(args)}", 196)
  end

  def r({response, state}) do
    pimp("🎯: #{response}", 226)
    {response, state}
  end

  def r(result) do
    pimp("🎯: #{result}", 226)
    result
  end

  def tell(msg, name \\ "user") do
    msg = replace(msg, "\\n", "\n")
    nl = contains?(msg, "\n") && "\n" || ""
    pimp("📢 #{name}:#{nl}#{msg}", 226)
  end

  defp pimp(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end

  defp log(emoji, name, %{parts: [%{text: text}], role: "user"}, color) do
    pimp("#{emoji} #{name}: #{text}", color)
  end

  defp log(emoji, name, [%{"text" => text}], color) do
    pimp("#{emoji} #{name}: #{text}", color)
  end

  defp log(emoji, name, text, color) when is_binary(text) do
    pimp("#{emoji} #{name}: #{text}", color)
  end

  defp log(emoji, name, result, color) do
    pimp("#{emoji} #{name}: #{inspect(result)}", color)
  end
end
