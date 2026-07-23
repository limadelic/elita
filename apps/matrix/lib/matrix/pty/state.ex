defmodule Matrix.Pty.State do
  @moduledoc false
  import Map, only: [merge: 2]

  @defaults %{
    ready: false,
    buffer: [],
    tail: "",
    pending_msg: nil,
    idle: false,
    idle_count: 0
  }

  def initial(pty, out, raw, child) do
    merge(@defaults, %{pty: pty, out: out, raw: raw, child: child})
  end

  def config(state, cfg) do
    merge(state, attrs(cfg))
  end

  defp attrs(cfg) do
    merge(pty(cfg), inject(cfg))
  end

  defp pty(cfg) do
    %{file: cfg[:file], port: cfg[:port], input: cfg[:input], taps: cfg[:taps]}
  end

  defp inject(cfg) do
    %{wait: cfg[:wait], target: cfg[:target], ask: cfg[:ask]}
    |> merge(%{put: cfg[:put], collect: cfg[:collect]})
  end
end
