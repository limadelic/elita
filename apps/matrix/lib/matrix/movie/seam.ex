defmodule Matrix.Movie.Seam do
  @moduledoc false
  import Matrix.Movie.Record

  def save(nil, _data), do: :ok
  def save(rec, data), do: record(rec, data)

  def done(nil, _name), do: :ok
  def done(rec, _name), do: done(rec)
end
