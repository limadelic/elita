defmodule Tools.User.Def.Schema do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2]

  def get(tool, _state) when tool != nil do
    spec = %{name: tool.name, description: tool.body}
    with_params(spec, tool[:params])
  end

  def get(nil, _state), do: nil

  defp with_params(spec, nil), do: spec
  defp with_params(spec, ""), do: spec

  defp with_params(spec, params) do
    names = split(params, ",") |> map(&trim/1)
    Map.put(spec, :parameters, params_spec(names))
  end

  defp params_spec(names) do
    %{
      type: "object",
      properties: params_properties(names),
      required: names
    }
  end

  defp params_properties(names) do
    Map.new(names, fn name -> {String.to_atom(name), %{type: "string"}} end)
  end
end

defmodule Tools.User.Def do
  defdelegate spec(tool, state), to: Tools.User.Def.Schema, as: :get
end
