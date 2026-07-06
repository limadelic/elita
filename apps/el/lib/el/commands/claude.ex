defmodule El.Commands.Claude do
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 1]

  def execute do
    cmd(~c"stty raw -echo -isig < /dev/tty")
    run(:claude)
  after
    cmd(~c"stty sane < /dev/tty")
  end
end
