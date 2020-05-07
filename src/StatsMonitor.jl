module StatsMonitor

using Sockets
using Statistics
using Dates
using JSON3
using OrderedCollections
using AbstractTrees
using OnlineStats
using StatsBase
using RecipesBase

export Stats, fit!

include("stats.jl")



# #-----------------------------------------------------------------------------# Backend
# abstract type Backend end

# struct TerminalBackend <: Backend end

# #-----------------------------------------------------------------------------# functions 
# const functions = OrderedDict(
#     1 => sum,
#     2 => mean,
#     3 => x -> quantile(x, [0, .25, .5, .75, 1])
# )


# #-----------------------------------------------------------------------------# Bucket
# struct Bucket{T}
#     f::Int
#     data::Vector{T}
# end
# calc(o::Bucket) = (value=functions[o.f](o.data), n=length(o.data), f=o.f)


# #-----------------------------------------------------------------------------# StatServer
# struct StatServer{B<:Backend}
#     buckets_int::Dict{Symbol, Bucket{Int}}
#     buckets_float::Dict{Symbol, Bucket{Float64}}
#     buckets_string::Dict{Symbol, Bucket{String}}
#     port::Int
#     backend::B
#     interval::Int
# end
# function StatServer(; port=8125, backend=TerminalBackend(), interval=5)
#     _b(T::Type) = Dict{Symbol, Bucket{T}}()
#     StatServer(_b(Int), _b(Float64), _b(String), port, backend, interval)
# end
# function Base.empty!(o::StatServer) 
#     empty!(o.buckets_int)
#     empty!(o.buckets_float)
#     empty!(o.buckets_string)
# end

# function start(o::StatServer)
#     @info "Listening on port $(o.port)..."
#     server = listen(o.port)
#     @info "Creating Timer..."
#     timer = Timer(1, interval=o.interval) do x
#         flush(o)
#         empty!(o)
#     end
#     while true 
#         sock = accept(server)
#         @async while isopen(sock)
#             s = readline(sock)
#             # try 
#                 msg = Meta.parse(s)
#                 data = eval_msg(msg)
#                 push!(o, data)
#             # catch ex 
#             #     @warn ex
#             # end
#         end
#     end
#     close(timer)
#     close(server)
# end

# function eval_msg(ex)
#     ok = ex.head === :tuple && 
#         ex.args[1] isa QuoteNode &&
#         ex.args[1].value isa Symbol && 
#         ex.args[2] isa Int && 
#         ex.args[3] isa Union{Int, Float64, String}
#     ok || error("Message has issues: $ex")
#     eval(ex)
# end

# function Base.push!(o::StatServer, data::Tuple)
#     id, function_id, value = data 
#     b = getbucket(o, value)
#     haskey(b, id) ? push!(b[id].data, value) : (b[id] = Bucket(function_id, [value]))
# end

# getbucket(o::StatServer, ::Int) = o.buckets_int
# getbucket(o::StatServer, ::Float64) = o.buckets_float
# getbucket(o::StatServer, ::String) = o.buckets_string

# #-----------------------------------------------------------------------------# flush 
# function flush(o::StatServer{TerminalBackend})
#     println("Output at time :$(now())")
#     for (k,v) in o.buckets_int 
#         printstyled("  > $k: $(calc(v))\n", color=:green)
#     end
#     for (k, v) in o.buckets_float 
#         printstyled("  > $k: $(calc(v))\n", color=:cyan)
#     end 
#     for (k, v) in o.buckets_string 
#         printstyled("  > $k: $(calc(v))\n", color=:yellow)
#     end
# end

end # module
