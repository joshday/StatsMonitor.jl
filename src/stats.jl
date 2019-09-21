#-----------------------------------------------------------------------# Mean
struct Mean
    μ::Float64
    n::Int
end
Mean() = Mean(0.0, 0)
function update(o::Mean, y)
    n = o.n + 1
    Mean(o.μ + (1 / n) * (y - o.μ), n)
end

#-----------------------------------------------------------------------# Sum
struct Sum
    value::Float64
    n::Int
end
Sum() = Sum(0.0, 0)
update(o::Sum, y) = Sum(o.value + y, o.n + 1)