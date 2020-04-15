module StatsMonitor

using Sockets
using Statistics
using Dates
using JSON3
using OrderedCollections

#-----------------------------------------------------------------------------# Backend
abstract type Backend end

struct TerminalBackend <: Backend end

#-----------------------------------------------------------------------------# functions 
const functions = OrderedDict(
    1 => sum,
    2 => mean
)


#-----------------------------------------------------------------------------# Bucket
struct Bucket{T}
    f::Int
    data::Vector{T}
end
function Base.get!(o::Bucket) 
    result = functions[o.f](o.data)
    empty!(o.data)
    return result
end

#-----------------------------------------------------------------------------# StatServer
struct StatServer{B<:Backend}
    buckets_int::Dict{Symbol, Bucket{Int}}
    buckets_float::Dict{Symbol, Bucket{Float64}}
    buckets_string::Dict{Symbol, Bucket{String}}
    port::Int
    backend::B
    interval::Int
end
function StatServer(; port=8125, backend=TerminalBackend(), interval=5)
    _b(T::Type) = Dict{Symbol, Bucket{T}}()
    StatServer(_b(Int), _b(Float64), _b(String), port, backend, interval)
end
empty!(o::StatServer) = (empty!(o.buckets_int); empty!(o.buckets_float); empty!(o.buckets_string))

function start(o::StatServer)
    @info "Listening on port $(o.port)..."
    server = listen(o.port)
    @info "Creating Timer..."
    timer = Timer(1, interval=o.interval) do x
        @info "flushing..."
        try
            flush(o)
        catch ex
            @info "flushing didn't work" ex
        finally
            empty!(o)
        end
    end
    while true 
        @info "message received..."
        sock = accept(server)
        @async while isopen(sock)
            s = readline(sock)
            @info "Message: $s"
            try 
                msg = Meta.parse(s)
                @info "msg: $msg"
                data = eval_msg(msg)
                @info "data: $data"
                push!(o, data)
            catch ex 
                @warn ex
            end
        end
    end
    close(timer)
    close(server)
end

function eval_msg(ex)
    ok = ex.head === :tuple && 
        ex.args[1] isa QuoteNode &&
        ex.args[1].value isa Symbol && 
        ex.args[2] isa Int && 
        ex.args[3] isa Union{Int, Float64, String}
    ok || error("Data has issues: $ex")
    eval(ex)
end

function Base.push!(o::StatServer, data::Tuple)
    id, function_id, value = data 
    b = getbucket(o, value)
    haskey(b, id) ? push!(b[id].data, value) : (b[id] = Bucket(function_id, [value]))
end

getbucket(o::StatServer, ::Int) = o.buckets_int
getbucket(o::StatServer, ::Float64) = o.buckets_float
getbucket(o::StatServer, ::String) = o.buckets_string

#-----------------------------------------------------------------------------# flush 
function flush(o::StatServer{TerminalBackend})
    out = OrderedDict{Symbol, Any}()
    for (k,v) in o.buckets_int 
        out[k] = functions[v.f](v.data)
    end
    for (k, v) in o.buckets_float 
        out[k] = functions[v.f](v.data)
    end 
    for (k, v) in o.buckets_string 
        out[k] = functions[v.f](v.data)
    end
    println(out)
end


# #-----------------------------------------------------------------------# tcp_server
# # expects message like: """{ "my_id": { "mean": $(randn()) } }"""
# function tcp_server(c::Config = Config())
#     server = listen(c.port)
#     buckets = init_buckets()
#     timer = Timer(_ -> flush!(buckets, c), 1, interval=c.interval)
#     while true
#         sock = accept(server)
#         @async while isopen(sock)
#             js = JSON3.read(readline(sock))
#             for (k, v) in pairs(js)
#                 if haskey(buckets, k)
#                     push!(buckets[k].data, first(values(v)))
#                 else
#                     for (k2, v2) in pairs(v)
#                         setindex!(buckets, (data=[v2], stat=get_stat(k2)), k)
#                     end
#                 end
#             end
#         end
#     end
#     close(timer)
#     close(server)
# end


# using Sockets
# using Statistics
# using JSON3
# using Dates
# using OnlineStatsBase

# #-----------------------------------------------------------------------# Terms
# # - A "bucket" maps an ID (Symbol) to an "aggregator"
# # - A "backend" is where the aggregated values are sent to.

# #-----------------------------------------------------------------------# init_bucket
# # id => (agg_type => bucket)
# init_buckets() = Dict{Symbol, Pair{Symbol, OnlineStat}}()

# # fallbacks are for OnlineStats
# add_to_bucket!(bucket, y) where {T} = fit!(last(bucket), y)
# apply_agg(bucket)  = bucket

# function init_bucket(s::Symbol)
#     s === :m && return :m => Mean()
#     s === :s && return :s => Sum()
#     s === :c && return :c => Counter()
#     s === :e && return :e => Extrema()
#     return @error "well that shouldn't have happened"
# end

# #-----------------------------------------------------------------------# Backend
# abstract type Backend end

# struct Terminal <: Backend end
# function send(out, backend::Terminal)
#     println("timestamp: ", Dates.format(now(), "yyyymmddTH:M:S"))
#     for (k, v) in pairs(out)
#         println("  > $k: $v")
#     end
# end

# #-----------------------------------------------------------------------# Config
# struct Config{B <: Backend, T}
#     port::Int
#     buckets::T
#     backend::B
#     interval::Int
# end
# function Config(;port=8125, buckets=init_buckets(), backend=Terminal(), interval=1)
#     Config(port, buckets, backend, interval)
# end

# function flush!(c::Config)
#     send(c.buckets, c.backend)
#     empty!(c.buckets)
# end

# #-----------------------------------------------------------------------# UDP
# function udp_server(opts::Config = Config())
#     sock = UDPSocket()
#     bind(sock, ip"127.0.0.1", opts.port)
#     timer = Timer(t -> flush!(opts), 1, interval=opts.interval)
#     while true
#         handle_message!(opts.buckets, recv(sock))
#     end
#     close(timer)
#     close(sock)
# end

# #-----------------------------------------------------------------------# TCP
# # broken
# function tcp_server(opts::Config = Config())
#     server = listen(opts.port)
#     timer = Timer(t -> flush!(opts), 1, interval=opts.interval)
#     while true
#         sock = accept(server)
#         @async while isopen(sock)
#             handle_message!(opts.buckets, sock.buffer)
#         end
#     end
#     close(timer)
#     close(server)
# end

# #-----------------------------------------------------------------------# ZMQ
# # broken
# function zmq_server(opts::Config = Config())
#     sock = Socket(SUB)
#     @info "Binding SUB Socket to $(opts.port)"
#     bind(sock, "tcp://*:$(opts.port)")
#     timer = Timer(t -> flush!(opts), 1, interval=opts.interval)
#     while true
#         try
#             msg = recv(sock, String)
#             handle_message!(opts.buckets, msg)
#         catch err
#             @warn err
#         end
#     end
#     close(timer)
#     close(sock)
# end

# #-----------------------------------------------------------------------# handle_message!
# function handle_message!(buckets, msg)
#     for (k, v) in pairs(JSON3.read(msg))
#         bucket_type, value = first(v)
#         add_to_bucket!(get!(buckets, k, init_bucket(bucket_type)), value)
#     end
# end

end # module
