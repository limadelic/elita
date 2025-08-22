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
    formatted = format_args(name, args)
    puts("#{IO.ANSI.red()}T: #{name}(#{formatted})#{IO.ANSI.reset()}")
  end

  defp format_args("tell", %{"message" => msg, "recipient" => to}) do
    clean_msg = String.replace(msg, "\\n", "\n")
    truncated = if String.contains?(clean_msg, "\n") do
      # Keep structured data like boards intact
      clean_msg
    else
      # Only truncate single line messages
      if String.length(clean_msg) > 60 do
        String.slice(clean_msg, 0, 57) <> "..."
      else
        clean_msg
      end
    end
    "#{truncated} → #{to}"
  end

  defp format_args(_, args), do: inspect(args)

  def r(result) do
    puts("#{IO.ANSI.light_yellow()}→ #{inspect(result)}#{IO.ANSI.reset()}")
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
