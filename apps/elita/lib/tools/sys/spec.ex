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
  import Log, only: [log: 5, agent: 5]
  import Cfg, only: [config: 1]

  @icon "🧪"

  defdelegate spec(name, state), to: Tools.Sys.Spec.Schema, as: :get

  def icon, do: @icon

  def exec(_, %{"name" => name}, %{config: config, name: agent} = state) do
    spec = config("#{name}_spec")
    audit(spec, name, agent, config, state)
  end

  defp audit(spec, name, agent, config, state) do
    key = "#{name}_spec"
    log(@icon, key, ":", "\n#{spec.content}\n", :white)
    agent(@icon, key, ":", "\n#{spec.content}\n", %{name: agent})
    {spec.content, %{state | config: config ++ [spec]}}
  end
end
