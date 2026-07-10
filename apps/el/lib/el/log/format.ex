defmodule El.Log.Format do
  def format(event, _config) do
    {level, msg, ts} = extract(event)
    time = stamp(ts)
    "#{time} #{level} #{msg}\n"
  end

  defp extract({level, _gl, {_mod, msg, ts, _md}, _extras}) do
    {level, format_msg(msg), ts}
  end

  defp format_msg({fmt, args}), do: safe_format(fmt, args)
  defp format_msg(msg), do: inspect(msg)

  defp safe_format(fmt, args) do
    try do
      :io_lib.format(fmt, args) |> IO.iodata_to_binary()
    rescue
      _ -> inspect({fmt, args})
    end
  end

  defp stamp(ts) do
    ts
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_string()
  end
end
