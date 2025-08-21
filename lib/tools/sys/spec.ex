defmodule Tools.Sys.Spec do
  import File, only: [read: 1]
  
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
    path = "agents/specs/#{name}_spec.md"
    {:ok, content} = read(path)
    spec = Cfg.config("specs/#{name}_spec") |> Map.put(:name, "#{name}_spec")
    {content, %{state | config: config ++ [spec]}}
  end
end