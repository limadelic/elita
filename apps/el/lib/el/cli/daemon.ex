defmodule El.CLI.Daemon do
  @moduledoc "Starts and maintains the daemon node."
  import El.Distribution, only: [start_daemon: 0]

  def execute do
    start_daemon()
    boot_app()
    hold_forever()
  end

  defp boot_app do
    Application.ensure_all_started(:elita)
  end

  defp hold_forever do
    Process.sleep(:infinity)
  end
end
