defmodule El.Pty.Config do
  @moduledoc false
  import Keyword, only: [get: 3, drop: 2]
  import El.Pty.Size, only: [default: 0]

  def build(cmd, opts) do
    [file: file(opts), port: port(opts), cmd: cmd] ++
      [get_size: size(opts), input: input(opts), taps: taps(opts)]
  end

  def finalize(opts, _cmd) do
    drop(opts, [:input, :taps, :cmd, :resize]) ++ defaults(opts)
  end

  defp defaults(opts) do
    [
      input: get(opts, :input, fn x -> x end),
      taps: get(opts, :taps, [])
    ]
  end

  defp file(opts), do: get(opts, :file, :file)
  defp port(opts), do: get(opts, :port, Port)
  defp size(opts), do: get(opts, :get_size, &default/0)
  defp input(opts), do: get(opts, :input, fn x -> x end)
  defp taps(opts), do: get(opts, :taps, [])
end
