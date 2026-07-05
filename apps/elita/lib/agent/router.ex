defmodule Agent.Router do
  import Elita, only: [call: 2, cast: 2]
  import Agent.Registry, only: [lookup: 1]
  import Agent.Session, only: [ask: 2]
  alias Agent.Session

  def route(name, :ask, message) do
    lookup(name)
    |> ask_route(name, message)
  end

  def route(name, :tell, message) do
    lookup(name)
    |> tell_route(name, message)
  end

  defp ask_route({:ok, {_pid, nil}}, name, message) do
    call(name, message)
    |> wrap_ok()
  rescue
    _ -> {:error, :not_found}
  end

  defp ask_route({:ok, {pid, _}}, _name, message) do
    ask(pid, message)
  end

  defp ask_route({:error, _}, name, message) do
    markdown_ask(name, message)
  end

  defp tell_route({:ok, {_pid, nil}}, name, message) do
    cast(name, message)
    :ok
  end

  defp tell_route({:ok, {pid, _}}, _name, message) do
    Session.cast(pid, message)
    :ok
  end

  defp tell_route({:error, _}, name, message) do
    markdown_tell(name, message)
  end

  defp markdown_ask(name, message) do
    call(name, message)
    |> wrap_ok()
  rescue
    _ -> {:error, :not_found}
  end

  defp markdown_tell(name, message) do
    cast(name, message)
    :ok
  rescue
    _ -> {:error, :not_found}
  end

  defp wrap_ok(value) do
    {:ok, value}
  end
end
