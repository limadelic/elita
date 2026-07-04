defmodule Tools.Sys.Spec.Schema do
  def get(name, _state) do
    %{name: name, description: "Read specification file", parameters: params()}
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name"]}
  end

  defp properties do
    %{name: %{type: "string", description: "Spec name to read"}}
  end
end

defmodule Tools.Sys.Spec do
  import Log, only: [log: 5]

  defdelegate spec(name, state), to: Tools.Sys.Spec.Schema, as: :get

  def exec(_, %{"name" => name}, %{config: config} = state) do
    name = "#{name}_spec"
    spec = Cfg.config(name)
    log("🧪", name, ":", "\n#{spec.content}\n", :white)
    {spec.content, %{state | config: config ++ [spec]}}
  end
end
