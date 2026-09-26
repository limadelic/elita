require 'openssl'
require 'json'
require 'base64'
require 'timeout'

module FreeqSasl
  ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  def load_key(name)
    path = File.expand_path("features/support/keys/#{name}.key")
    seed = File.binread(path)
    OpenSSL::PKey.new_raw_private_key("ED25519", seed)
  end

  def build_did(key)
    public_key = key.raw_public_key
    "did:key:z" + base58btc("\xED\x01".b + public_key)
  end

  def base58btc(bytes)
    zeros = bytes[/\A\x00*/n].size
    num = 0
    bytes.each_byte { |b| num = num * 256 + b }
    digits = num.digits(58).reverse.map { |d| ALPHABET[d] }
    (["1"] * zeros + digits).join
  end

  def encode(bytes)
    Base64.urlsafe_encode64(bytes, padding: false)
  end

  def challenge(socket)
    write_line(socket, "AUTHENTICATE ATPROTO-CHALLENGE")
    line = read_line(socket, /^AUTHENTICATE /)
    encoded = line.split(" ", 2)[1]
    padding = (4 - encoded.length % 4) % 4
    encoded += "=" * padding
    Base64.urlsafe_decode64(encoded)
  end

  def sign(key, challenge)
    key.sign(nil, challenge)
  end

  def msgsig(socket, public_key)
    write_line(socket, "MSGSIG #{encode(public_key)}")
    read_line(socket, /MSGSIG OK/)
  end

  def sasl_authenticate(socket, name)
    key = load_key(name)
    signature = sign(key, challenge(socket))
    auth_data = JSON.generate({ did: build_did(key), signature: encode(signature) })
    write_line(socket, "AUTHENTICATE #{encode(auth_data)}")
    read_line(socket, / 903 /)
  end

  def write_line(socket, line)
    socket.write("#{line}\r\n")
    socket.flush
  end

  def read_line(socket, pattern)
    Timeout.timeout(5, RuntimeError, "freeq: no #{pattern.inspect} in 5s") do
      loop { (line = socket.gets.to_s.chomp).match?(pattern) and return line }
    end
  end
end
