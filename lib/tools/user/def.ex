defmodule Tools.User.Def do
  def def(tool) when tool != nil do
    %{
      name: tool.name,
      description: tool.body
    }
  end

  def def(nil), do: nil
end
