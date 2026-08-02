defmodule El.Commands.Rouse do
  @moduledoc false
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]

  def native(n, config, tape), do: spawn(n, [config], tape_env: tape)
end
