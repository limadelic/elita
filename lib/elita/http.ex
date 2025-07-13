defmodule Elita.HTTP do
  @moduledoc """
  HTTP server for agent requests
  """

  def child_spec(_) do
    Bandit.child_spec(
      plug: Elita.Router,
      scheme: :http,
      port: 4000
    )
  end
end