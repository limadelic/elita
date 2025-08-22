defmodule Log do
  import Format
  import IO, only: [puts: 1]

  def q(arg, name \\ "user")
  
  def q(prompt, name) when is_map(prompt) do
    prompt[:contents]
    |> Kernel.||([])
    |> List.last()
    |> log(name)

    prompt
  end

  def q(text, name) when is_binary(text) do
    pimp("🤔 #{name}: #{text}", 82)
  end

  def a(result, name \\ "user") do
    log(result, name)
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

  defp log(%{parts: [%{text: text}], role: "user"}, name) do
    pimp("🤔 #{name}: #{text}", 82)
  end

  defp log([%{"text" => text}], name) do
    pimp("✨ #{name}: #{text}", 255)
  end

  defp log(_, _) do
    nil
  end
end
