defmodule Glob do
  import String, only: [contains?: 2]
  import Path, only: [split: 1]

  def match?(entry_path, pattern) do
    match(split(entry_path), split(pattern))
  end

  def wild?(pattern) do
    contains?(pattern, ["*", "**"])
  end

  def match(_, []), do: true
  def match([], ["**" | t]), do: match([], t)
  def match([], _), do: false
  def match(e, ["**" | t]), do: unwind(match(e, t), e, t)
  def match([_ | et], ["*" | pt]), do: match(et, pt)
  def match([eh | et], [eh | pt]), do: match(et, pt)
  def match([_ | _], [_ | _]), do: false

  def unwind(true, _e, _t), do: true
  def unwind(false, [_ | et], t), do: match(et, ["**" | t])
  def unwind(false, [], _t), do: false
end
