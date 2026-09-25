require 'socket'

module FreeqClientSpec
  def close_session(session)
    socket = session.dig(:socket)
    socket.write("QUIT\r\n")
    socket.flush
    socket.close
  end
end

RSpec.describe FreeqClientSpec do
  it 'sends QUIT before closing socket' do
    socket_double = instance_double(TCPSocket)
    session = { socket: socket_double }
    tester = Object.new.extend(FreeqClientSpec)

    expect(socket_double).to receive(:write).with("QUIT\r\n").ordered
    expect(socket_double).to receive(:flush).ordered
    expect(socket_double).to receive(:close).ordered

    tester.close_session(session)
  end
end
