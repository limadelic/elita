defmodule El.TextFormat do
  @moduledoc false
  import :binary, only: [at: 2]

  def format(msg) do
    pick_format(String.contains?(msg, "\n"), msg)
  end

  defp pick_format(true, msg), do: bracket_paste(msg)
  defp pick_format(false, msg), do: pick_format_alt(control_sequence?(msg), msg)

  defp pick_format_alt(true, msg), do: msg
  defp pick_format_alt(false, msg), do: append_return(msg)

  defp bracket_paste(msg), do: "\e[200~#{msg}\e[201~\r"
  defp append_return(msg), do: "#{msg}\r"

  defp control_sequence?(msg) do
    is_special_byte(at(msg, 0))
  end

  defp is_special_byte(nil), do: false
  defp is_special_byte(byte) when byte < 32, do: true
  defp is_special_byte(0x1B), do: true
  defp is_special_byte(_), do: false
end
