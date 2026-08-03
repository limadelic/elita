defmodule Matrix.Movie.Play do
  @moduledoc false

  def open(_spec, _opts) do
    :play_port
  end

  def command(_handle, _data) do
    :ok
  end

  def close(_handle) do
    :ok
  end

  def info(_handle, :os_pid) do
    {:os_pid, 1}
  end

  def info(_handle, _key) do
    nil
  end
end
