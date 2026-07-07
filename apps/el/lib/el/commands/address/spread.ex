defmodule El.Commands.Address.Spread do
  import El.Commands.Address.Wake, only: [up: 1]
  import El.Commands.Address.Send, only: [tell: 3]
  import Enum, only: [uniq_by: 2, each: 2]

  def fanout(entries, msg, tool) do
    unique = uniq_by(entries, &{&1.name, &1.path})
    each(unique, &up/1)
    each(unique, fn e -> tell(e.name, msg, tool) end)
  end
end
