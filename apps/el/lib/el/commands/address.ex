defmodule El.Commands.Address do
  defdelegate route(recipient, msg, mode, tool), to: El.Commands.Address.Route
end
