import Config

# Configure the tape handler - it checks TAPE at runtime
config :elita, tape_handler: &Tape.handle/4

config :elita, :clock, &Clock.now/0
