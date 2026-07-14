defmodule Agent.Puppet do
  def cwd do
    Node.list() |> scan()
  catch
    _, _ -> nil
  end

  defp scan([]), do: nil

  defp scan([node | rest]) do
    node |> fetch() |> accept(rest)
  end

  defp fetch(node) do
    :erpc.call(node, System, :cwd, [])
  rescue
    _ -> nil
  end

  defp accept(cwd, _rest) when is_binary(cwd), do: cwd
  defp accept(nil, rest), do: scan(rest)
end
