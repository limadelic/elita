defmodule Tools.Sys.Silk.Schema do
  def get(name, _state) do
    %{name: name, description: "Read silk file", parameters: params()}
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name"]}
  end

  defp properties do
    %{name: %{type: "string", description: "Silk name to read"}}
  end
end

defmodule Tools.Sys.Silk do
  import Log, only: [log: 5]

  defdelegate def(name, state), to: Tools.Sys.Silk.Schema, as: :get

  def exec(_, %{"name" => name}, state) do
    content = Utils.File.file("#{name}.md")
    log("🕸️", name, ":", "\n#{content}\n", :white)
    {content, state}
  end
end
