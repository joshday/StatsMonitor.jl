struct Stats{A,B,C,D,I}
    number_stats::OrderedDict{Symbol, A}
    string_stats::OrderedDict{Symbol, B}
    bool_stats::OrderedDict{Symbol, C}
    null_stats::OrderedDict{Symbol, D}
    interval::I

    function Stats(interval::I = Second(10)) where {I}
        A = typeof(init_stat(Number))
        B = typeof(init_stat(String))
        C = typeof(init_stat(Bool))
        D = typeof(init_stat(Nothing))
        new{A,B,C,D,I}(
            OrderedDict{Symbol, A}(), 
            OrderedDict{Symbol, B}(), 
            OrderedDict{Symbol, C}(),
            OrderedDict{Symbol, D}(),
            interval
        )
    end
end

init_stat(::Type{<:Number}) = GroupBy(DateTime, Series(Variance(), Extrema(), ExpandingHist(100)))
init_stat(::Type{String}) = GroupBy(DateTime, CountMap(String))
init_stat(::Type{Bool}) = GroupBy(DateTime, CountMap(Bool))
init_stat(::Type{Nothing}) = GroupBy(DateTime, Counter(Nothing))

get_stats(o::Stats, ::Type{<:Number}) = o.number_stats 
get_stats(o::Stats, ::Type{String}) = o.string_stats 
get_stats(o::Stats, ::Type{Bool}) = o.bool_stats 
get_stats(o::Stats, ::Type{Nothing}) = o.null_stats

#-----------------------------------------------------------------------------# fit! 
function StatsBase.fit!(o::Stats, x::Pair{Symbol, T}) where {T}
    stat = get(get_stats(o, T), x[1], init_stat(T))
    get_stats(o, T)[x[1]] = fit!(stat, round(now(), o.interval) => x[2])
    o
end

#-----------------------------------------------------------------------------# printing
Base.show(io::IO, o::Stats) = print_tree(io, o)
AbstractTrees.printnode(io::IO, o::Stats) = print(io, "Stats")
function AbstractTrees.children(o::Stats) 
    d = reduce((a,b) -> merge(vcat, a, b), [o.number_stats, o.string_stats, o.bool_stats, o.null_stats])
    collect(d)
end


@recipe function f(o::Stats) 
    dicts = [o.number_stats, o.string_stats, o.bool_stats, o.null_stats]
    nplots = sum(length(keys(d)) for d in dicts)
    a, b = typemax(DateTime), typemin(DateTime)
    layout --> nplots
    i = 0
    for dict in dicts
        i += 1
        for (k, v) in dict
            @series begin 
                label --> string(k)
                subplot --> i
                a = min(a, minimum(keys(v.value)))
                b = max(b, maximum(keys(v.value)))
                [(t, t + o.interval) => stat for (t,stat) in v.value]
            end
        end
    end
    @info a, b
    xlim --> (a, b)
    nothing
end