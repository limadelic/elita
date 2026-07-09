defmodule Mix.Tasks.Cover do
  @compile {:no_warn_undefined, El.Cover}

  def run(argv) do
    El.Cover.run(argv)
  end
end
