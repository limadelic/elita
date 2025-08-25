defmodule Tools.Sys.Spec do
  import Utils.File, only: [file: 1]
  
  def def(name, _state) do
    %{
      name: name,
      description: "Read specification file",
      parameters: %{
        type: "object", 
        properties: %{
          name: %{type: "string", description: "Spec name to read"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name}, %{config: config} = state) do
    spec = file("#{name}_spec.md")
    cfg = Cfg.config("#{name}_spec") |> Map.put(:name, "#{name}_spec")
    {agent, %{state | config: config ++ [cfg]}}
  end
end