defmodule Tools.User.Def.Schema do
  def get(tool, _state) when tool != nil do
    %{
      name: tool.name,
      description: tool.body
    }
  end

  def get(nil, _state), do: nil
end

defmodule Tools.User.Def do
  defdelegate def(tool, state), to: Tools.User.Def.Schema, as: :get
end
