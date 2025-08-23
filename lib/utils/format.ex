defmodule Format do

  def yaml(args) when is_map(args) do
    args
    |> Map.drop(["__struct__"])
    |> Ymlr.document!()
    |> String.replace_prefix("---", "")
  rescue
    _ -> "#{inspect(args)}"
  end

end
