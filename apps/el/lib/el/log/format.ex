defmodule El.Log.Format do
  import DateTime, only: [from_unix!: 2, to_iso8601: 1]
  import IO, only: [iodata_to_binary: 1]

  def format(event, _config) do
    {level, msg, ts} = extract(event)
    time = stamp(ts)
    "#{time} #{level} #{msg}\n"
  end

  defp extract({level, _gl, {_mod, msg, ts, _md}, _extras}) do
    {level, text(msg), ts}
  end

  defp text({fmt, args}) do
    render(fmt, args) |> iodata_to_binary()
  rescue
    _ -> inspect({fmt, args})
  end

  defp text(msg), do: inspect(msg)

  defp stamp(ts) do
    ts |> from_unix!(:millisecond) |> to_iso8601()
  end

  defp render(fmt, args) do
    :io_lib.format(fmt, args)
  end
end
