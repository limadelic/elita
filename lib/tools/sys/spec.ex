defmodule Tools.Sys.Spec do
  import Log, only: [log: 5]

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
    name = "#{name}_spec"
    spec = Cfg.config(name)
    log("🧪", name, ":\n", spec.content, :white)
    {spec.content, %{state | config: config ++ [spec]}}
  end
end
