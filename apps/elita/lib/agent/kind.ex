defmodule Agent.Kind do
  @callback ask(entry :: list(), recipient :: binary(), message :: any()) ::
              any()
  @callback forward(entry :: list(), recipient :: binary(), message :: any()) ::
              any()
end
