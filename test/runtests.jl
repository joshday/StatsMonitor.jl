using StatsMonitor
using Test
using Sockets

@testset "StatsMonitor.jl" begin

bucket = Dict{Symbol,Vector{Float64}}()

opts = StatsMonitor.Config(bucket=bucket)
@async StatsMonitor.udp_server(opts)
sock = UDPSocket()

function test()
    t = Timer(t -> send(sock, ip"127.0.0.1", opts.port, """{ "myId": { "val": $(randn()), "stat": "m" } }"""), 1, interval=1/100)
    t2 = Timer(t -> send(sock, ip"127.0.0.1", opts.port, """{ "myId2": { "val": $(randn()), "stat": "m" } }"""), .9, interval=1/100)
    sleep(10)
    close(t)
    close(t2)
    close(sock)
end

test()
@info bucket
end
