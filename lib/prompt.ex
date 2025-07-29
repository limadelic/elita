defmodule Prompt do
  import Enum, only: [reverse: 1, join: 2]
  
  def prompt(config, history) do
    """
    #{config}
    
    History:
    #{history |> reverse() |> join("\n")}
    """
  end
end