require "cord"
sh = require "stormsh"

-- Packet Generation:
-- Each second, generate and send a packet to send to the server that contains the following info:
--  * sequence number (monotonically increasing)
--  * # of packets received so far (cumulative)
--  * last received sequence number
-- Send packets to: server_ip, port 7000.
-- Receive packets on: port 7000

received = 0
last_recv_seq_no = 0
send_seq_no = 0

server_ip = "2001:470:1f04:709::2"
server_port = 7000

-- received: sequence number from server
sock = storm.net.udpsocket(7000, function(msg, from, port)
    received = received + 1
    last_recv_seq_no = storm.mp.unpack(msg)
end)

rst = storm.net.udpsocket(6666, function()
    storm.os.reset()
end)


storm.os.invokePeriodically(1*storm.os.SECOND, function()
    tosend = {}
    tosend["seqno"] = send_seq_no
    tosend["received"] = received
    tosend["last"] = last_recv_seq_no
    storm.net.sendto(sock, storm.mp.pack(tosend), server_ip, server_port)
    send_seq_no = send_seq_no + 1
end)

sh.start()
cord.enter_loop()
