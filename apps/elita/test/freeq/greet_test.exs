defmodule Freeq.GreetTest do
  use ExUnit.Case

  @moduletag :freeq

  import Brian

  setup context do
    brian = join("#the-lab")
    say(brian, name(context))
    on_exit(fn -> leave(brian) end)
    :ok
  end

  test "greet" do
  end
end
