defmodule Matrix.Wrap.Reply do
  @moduledoc false
  import String, only: [to_atom: 1, trim: 1, trim_trailing: 2, split: 3]
  import IO, only: [write: 1]

  def handle(:forward, _), do: :forward
  def handle(output, sender), do: handle(output, sender, [])
  def handle(:forward, _, _opts), do: :forward

  def handle(output, sender, opts) do
    extracted = extract(output)
    agent = fix(sender, sender)
    opts[:target].(agent) |> route(extracted, agent)
    {:handled}
  end

  defp extract(binary) when is_binary(binary),
    do: binary |> split("\n", parts: 2) |> reply(binary)

  defp extract(other), do: other

  defp reply(["[reply " <> rest, message], _original),
    do: rest |> split("]", parts: 2) |> body(message)

  defp reply(_, original), do: original

  defp body([_sender, ""], message), do: message
  defp body(_, original), do: original

  def fix(a, _) when is_atom(a), do: a
  def fix(_, b) when is_binary(b), do: to_atom(b)

  def prepare(name, _sender) do
    name |> trim() |> to_atom()
  end

  def inject(nil, _target, _message, _sender), do: :forward
  def inject(_pid, _target, _message, nil), do: :forward
  def inject(pid, target, message, sender), do: inject(pid, target, message, sender, [])

  def inject(nil, _target, _message, _sender, _opts), do: :forward
  def inject(_pid, _target, _message, nil, _opts), do: :forward

  def inject(pid, _target, message, sender, opts) do
    put = opts[:put]
    text = "[from #{sender |> fix(sender) |> to_string()}]\n#{message}"
    put.(pid, text)
  end

  defp route(nil, _, _), do: :ok

  defp route(pid, [%{"text" => text} | _], agent), do: route(pid, text, agent)

  defp route(_pid, output, agent) when is_binary(output) do
    cleaned = trim_trailing(output, "\n")
    write("#{cleaned}\n#{agent}> ")
  end

  defp route(_, _, _), do: :ok

  def known?(name, opts \\ []) do
    target = opts[:target]
    name |> trim() |> to_atom() |> target.() |> is_pid()
  rescue
    _ -> false
  end
end
