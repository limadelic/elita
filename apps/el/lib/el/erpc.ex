defmodule El.Erpc do
  @moduledoc false

  def call(node, module, fun, args) do
    :erpc.call(node, module, fun, args)
  end
end
