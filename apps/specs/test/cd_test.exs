defmodule CdTest do
  use SpecHelper

  test "cd sets standpoint to directory" do
    original = El.Standpoint.get()
    on_exit(fn -> El.Standpoint.set(original) end)

    target = File.cwd!()
    El.Commands.Cd.cd(target)

    assert El.Standpoint.get() == target
  end
end
