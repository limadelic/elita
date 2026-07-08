defmodule Mix.Tasks.Cover do
  @compile {:no_warn_undefined, El.Cover}

  def run(argv) do
    clean_argv = argv |> Enum.drop_while(&(&1 == "--"))
    El.Cover.run(clean_argv)
  end
end
