defmodule Tools.Sys.Agent do
  import Utils.Reader, only: [read_file: 1]
  
  def def(name, _state) do
    %{
      name: name,
      description: "Read agent definition file",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Agent name to read"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name}, state) do
    path = "agents/#{name}.md"
    content = read_file(path)
    {content, state}
  end
end