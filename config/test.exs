import Config

# Configure the tape handler - it checks TAPE at runtime
config :elita, tape_handler: &TapeHandler.handle/3

config :elita, :clock, fn -> {{2025, 7, 7}, {10, 0, 0}} end
