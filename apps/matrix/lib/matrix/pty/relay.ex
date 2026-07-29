defmodule Matrix.Pty.Relay do
  @moduledoc false
  import Matrix.Trace, only: [record: 1]
  import Matrix.Pty.Handler
  import Matrix.Pty.Log, only: [dump: 2]
  import Matrix.Pty.Notify, only: [notify: 2]
  import :os, only: [cmd: 1]
  import IO, only: [binwrite: 2]

  def data(pty, data, %{port: port, out: out, raw: raw, taps: taps} = state) do
    binwrite(out, data)
    dump(raw, data)
    notify(taps, data)
    respond(port, pty, data, state)
  end

  def stdin(port, pty, input, data) do
    record(data)
    write(port, pty, input.(data))
  end

  def terminal({rows, cols}) do
    "stty rows #{rows} cols #{cols} < /dev/tty" |> to_charlist() |> cmd()
  rescue
    _ -> :ok
  end
end
