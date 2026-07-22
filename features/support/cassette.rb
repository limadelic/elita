module Cassette
  def deliver
    setenv_script = File.expand_path("../setenv.exs", __FILE__)
    cassette_dir = File.expand_path("../cassettes", __dir__)
    system("elixir #{setenv_script} #{@cassette} #{cassette_dir} >/dev/null 2>&1")
  rescue StandardError
    nil
  end

  def revoke
    reset_script = File.expand_path("../reset.exs", __FILE__)
    system("elixir #{reset_script} >/dev/null 2>&1")
  rescue StandardError
    nil
  end
end
