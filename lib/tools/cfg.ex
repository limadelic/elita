defmodule Tools.Cfg do
  import String, only: [split: 2, trim: 1]

  def parse(path) do
    content = File.read!(path)
    parts = split(content, "---")
    # Skip empty first part, take second part as header, rest as body
    [_, header | body_parts] = parts
    meta = parse_yaml_header(header)
    body = Enum.join(body_parts, "---")
    {meta, body}
  end

  def blocks(body) do
    Regex.scan(~r/```elixir\n(.*?)\n```/s, body, capture: :all_but_first)
    |> Enum.map(&List.first/1)
  end

  defp parse_yaml_header(header) do
    split(trim(header), "\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case split(line, ":") do
        [key, value] -> Map.put(acc, trim(key), trim(value))
        _ -> acc
      end
    end)
  end
end