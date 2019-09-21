using StatsMonitor
using Test
using Sockets

opts = StatsMonitor.Config(interval=1)

@async StatsMonitor.tcp_server(opts)

s1() = """{ "myId": { "m": $(randn()), "tags": ["t1", "t2"] } }"""
s2() = """{ "myId2": { "c": 1, "tags": ["t2", "t3"] } }"""
s3() = """{ "myId3": { "s": $(rand(1:10)), "tags": ["t2", "t3"] } }"""

function test(n = 1000)
    sock = UDPSocket()

    for _ in 1:n
        send(sock, ip"127.0.0.1", 8125, s1())
        send(sock, ip"127.0.0.1", 8125, s2())
        send(sock, ip"127.0.0.1", 8125, s3())
    end

    close(sock)
end
test()

# function test2(n=10_000)
#     s1() = """{ "myId": { "mean": $(randn()), "tags": ["t1", "t2"] } }"""
#     s2() = """{ "myId2": { "omean": $(randn()), "tags": ["t2", "t3"] } }"""

#     sock = UDPSocket()
#     f1() = for i in 1:n; send(sock, ip"127.0.0.1", opts.port, s1()); end
#     f2() = for i in 1:n; send(sock, ip"127.0.0.1", opts.port, s2()); end

#     @time f1()
#     @time f1()
#     @time f2()
#     @time f2()
#     close(sock)
# end
# test2()
