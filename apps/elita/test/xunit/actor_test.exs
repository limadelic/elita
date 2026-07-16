defmodule ActorTest do
  use Tester
  @moduletag :xunit

  setup _context do
    spawn(:actor, :speck)
    :ok
  end

  @tag cassette: "actor_speck"
  @moduletag timeout: 120_000
  test "actor speck passes" do
    verify("passed", ask(:actor, "exec actor"))
  end
end
