defmodule Tools.User.Def.Schema do
  import Enum, only: [map: 2]
  import String, only: [split: 2, trim: 1]

  def get(tool, _state) when tool != nil do
    spec = %{name: tool.name, description: tool.body}
    armed(spec, tool[:params])
  end

  def get(nil, _state), do: nil

  defp armed(spec, nil), do: spec
  defp armed(spec, ""), do: spec

  defp armed(spec, params) do
    names = split(params, ",") |> map(&trim/1)
    Map.put(spec, :parameters, schema(names))
  end

  defp schema(names) do
    %{
      type: "object",
      properties: fields(names),
      required: names
    }
  end

  defp fields(names) do
    Map.new(names, fn name -> {String.to_atom(name), %{type: "string"}} end)
  end
end

defmodule Tools.User.Def do
  defdelegate spec(tool, state), to: Tools.User.Def.Schema, as: :get
end
