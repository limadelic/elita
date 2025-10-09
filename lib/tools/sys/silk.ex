defmodule Tools.Sys.Silk do
  import Log, only: [log: 5]

  def def(name, _state) do
    %{
      name: name,
      description: "Read silk file",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Silk name to read"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name}, %{config: config} = state) do
    silk = Cfg.config(name)
    log("🕸️", name, ":", "\n#{silk.content}\n", :white)
    {silk.content, %{state | config: config ++ [silk]}}
  end
end
