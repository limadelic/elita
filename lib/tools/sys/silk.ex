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

  def exec(_, %{"name" => name}, state) do
    content = Utils.File.file("#{name}.md")
    log("🕸️", name, ":", "\n#{content}\n", :white)
    {content, state}
  end
end
