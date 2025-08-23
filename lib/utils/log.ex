defmodule Log do
  import Format
  import IO, only: [puts: 1]
  import String, only: [contains?: 2, replace: 3]

  def q(text, name) do
    log("🤔", name, text)
  end

  def a(result, name \\ "user") do
    log("✨", name, result)
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
