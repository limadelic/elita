defmodule Log do
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
      |> then(&colored("🛠️: #{name}(#{&1})", 196))
  end

  defp format("tell", %{"message" => msg, "recipient" => to}) do
    truncated = msg
      |> String.replace("\\n", "\n")
      |> truncate()
    "#{truncated} → #{to}"
  end

  defp format(_, args), do: inspect args

  defp truncate(text) do
    case {String.contains?(text, "\n"), String.length(text)} do
      {false, len} when len > 60 -> String.slice(text, 0, 57) <> "..."
      _ -> text
    end
  end

  def r(result) do
    colored("🎯: #{inspect result}", 226)
    result
  end

  def tell(msg) do
    colored("📢: #{msg}", 226)
  end


  defp colored(text, code) do
    puts("\e[38;5;#{code}m#{text}\e[0m")
  end

  defp log(%{parts: [%{text: text}], role: "user"}) do
    colored("🤔: #{text}", 82)
  end

  defp log([%{"text" => text}]) do
    colored("✨: #{text}", 255)
  end

  defp log(_) do
    nil
  end

end
