#!/usr/bin/env elixir

:file.write_file("/private/tmp/claude-501/-Users-mike-dev-self-elita/2afd908c-b2e0-44ec-857d-7d91bd975077/scratchpad/file_write_test.log", "Test message\n", [:append])
IO.puts("File write completed")
