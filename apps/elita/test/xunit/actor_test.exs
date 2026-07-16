defmodule ActorTest do
  use Tester
  @moduletag :xunit

  setup context do
    System.put_env("CASSETTE", cassette_for(context.test))
    spawn(:actor, :speck)
    :ok
  end

  defp cassette_for(:"test actor speck passes"), do: "actor_speck"

  @moduletag timeout: 120_000
  test "actor speck passes" do
    verify("passed", ask(:actor, "exec actor"))
  end
end
