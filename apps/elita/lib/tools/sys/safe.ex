defmodule Tools.Sys.Safe do
  def call(fun, default) do
    fun.()
  catch
    _, _ -> default
  end
end
