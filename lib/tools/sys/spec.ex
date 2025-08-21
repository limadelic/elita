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

  def exec(_, %{"name" => name}, state) do
    path = "agents/specs/#{name}_spec.md"
    content = read_file(path)
    {content, state}
  end
end