module StatsMonitor

using Sockets
using OnlineStats
using JSON3
using Dates

#-----------------------------------------------------------------------# init_bucket
init_bucket() = Dict{Symbol, Vector{Float64}}()

#-----------------------------------------------------------------------# handle_message!
function handle_message!(bucket, msg)
    for (k, v) in pairs(JSON3.read(msg))
        haskey(bucket, k) ? push!(bucket[k], v.val) : (bucket[k] = [v.val])
    end
end

#-----------------------------------------------------------------------# Backend
abstract type StatsBackend end

struct Info <: StatsBackend end
send(out, backend::Info) = @info "Bucket:" time=now() value=out

#-----------------------------------------------------------------------# Config
struct Config{B <: StatsBackend}
    port::Int
    bucket::Dict{Symbol, Vector{Float64}}
    backend::B
    interval::Int
end
function Config(;port=8125, bucket=init_bucket(), backend=Info(), interval=1)
    Config(port, bucket, backend, interval)
end

function flush!(c::Config)
    out = Dict(k => (mean(v), var(v), length(v)) for (k, v) in pairs(c.bucket))
    map(empty!, values(c.bucket))
    send(out, c.backend)
end

#-----------------------------------------------------------------------# UDP
function udp_server(opts::Config = Config())
    sock = UDPSocket()
    bind(sock, ip"127.0.0.1", opts.port)
    timer = Timer(t -> flush!(opts), 1, interval=opts.interval)
    while true
        handle_message!(opts.bucket, recv(sock))
    end
    close(timer)
    close(sock)
end

end # module
