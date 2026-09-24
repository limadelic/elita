defmodule Freeq.GreetTest do
  use ExUnit.Case

  @moduletag :freeq

  import Brian

  brian "greet" do
    Freeq.spawn(:greet)
    pause()
  end
end
