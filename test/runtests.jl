using StatsMonitor
using ProgressMeter
using Dates


s = Stats(Second(1))

@showprogress for i in 1:2000
    sleep(.01)
    fit!(s, :id1 => randn() + i/1000)
    fit!(s, :id2 => i * randn())
    fit!(s, :id3 => rand(["A","A","B","C"]))

    # different data types, same id
    fit!(s, :id4 => rand() < .8)
    rand() < i/2000 && fit!(s, :id4 => nothing)
end

plot(s, size=(1000, 500))