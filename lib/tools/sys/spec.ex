defmodule Tools.Sys.Spec do
  import Utils.Reader, only: [read_file: 1]
  
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
    content = read_file("#{name}_spec.md")
    spec = Cfg.config("#{name}_spec") |> Map.put(:name, "#{name}_spec")
    {content, %{state | config: config ++ [spec]}}
  end
end