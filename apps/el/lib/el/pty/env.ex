defmodule El.Pty.Env do
  @moduledoc false
  def unset do
    [{~c"CLAUDE_CODE_SESSION_ID", false}, {~c"CLAUDECODE", false},
     {~c"CLAUDE_CODE_ENTRYPOINT", false}, {~c"ANTHROPIC_API_KEY", false},
     {~c"CLAUDE_CODE_CHILD_SESSION", false}]
  end
end
