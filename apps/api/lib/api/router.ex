defmodule Api.Router do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Api do
    pipe_through :api
    
    post "/agents/:name", AgentController, :act
    get "/agents/:name/state", AgentController, :state
    get "/agents/:name/stream", AgentController, :stream
  end
end