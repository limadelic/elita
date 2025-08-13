defmodule Tool.Index do
  import Tools, only: [exec: 1]

  def set(key, value) do
    exec(%{"name" => "set", "args" => %{"key" => "#{key}", "value" => value}})
  end

  def get(key) do
    exec(%{"name" => "get", "args" => %{"key" => "#{key}"}})
  end

  def tell(target, message) do
    exec(%{"name" => "tell", "args" => %{"recipient" => "#{target}", "message" => "#{message}"}})
  end
end