using Pkg; Pkg.activate(".")
using Strategems, Temporal, Indicators, Dates
using HDF5, JLD
using Statistics

function optimizer(universe::Universe, arg_ranges::Vector{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}}})
    # define indicators and parameter space
    arg_names = [:fastlimit, :slowlimit]
    arg_defaults = [0.5, 0.05]
    paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
    f(x; args...) = Indicators.mama(x; args...)
    indicator = Indicator(f, paramset)

    # define signals that will trigger trading decisions
    siglong = @signal MAMA ↑ FAMA
    sigshort = @signal MAMA ↓ FAMA
    sigexit = @signal MAMA == FAMA

    # define the trading rules
    longrule = @rule siglong → long 100
    shortrule = @rule sigshort → short 100
    exitrule = @rule sigexit → liquidate 1.0
    rules = (longrule, shortrule, exitrule)

    # run strategy
    strat = Strategy(universe, indicator, rules)
    bt = backtest(strat, px_trade=:open, px_close=:close, verbose=true)
    optimize(strat, px_trade=:open, px_close=:close)
end

function getMin(x::Float64, d::Float64)
    t = x - d
    t <= 0.01 ? 0.01 : t
end
function getMax(x::Float64, d::Float64)
    t = x + d
    t >= 0.99 ? 0.99 : t
end

function datasource(asset::String)::TS
    savedata_path = joinpath("/home/bane/projects/julia/local/Strategems.jl", pathCoins, "$asset")
    return Temporal.tsread(savedata_path, indextype=UInt64, format="yyyy-mm-dd HH:MM:SS")
end

function marketMA(asset::String)
    # define universe and gather data
    assets = [asset]
    universe = Universe(assets)
    universe = gather(assets, source=datasource)

    posLong = 1
    posShort = 2
    posPnl = 3
    ranger = [0.05, 0.025, 0.01]
    arg_ranges = [0.01:ranger[1]:0.99, 0.01:ranger[1]:0.99]
    opt = optimizer(universe, arg_ranges)

    n = size(opt)[1]

    for rng in ranger[2:end]
        #short long pnl

        maxPnl = maximum(opt[:, posPnl])
        pnls = Set(filter(x -> (x > maxPnl*0.9), opt[:, posPnl]))
        newOpt = opt[map(x -> (x==maxPnl), opt[:, 3]), :]
        longmin = minimum(newOpt[:,posLong])
        longmax = maximum(newOpt[:,posLong,])
        shortmin = minimum(newOpt[:,posShort,])
        shortmax = maximum(newOpt[:,posShort,])

        dif = rng * 2
        longrange = getMin(longmin, dif):rng:getMax(longmax, dif)
        println(longrange)
        shortrange = getMin(shortmin, dif):rng:getMax(shortmax, dif)
        println(shortrange)

        strat = optimizer(universe, [longrange, shortrange])
    end
    maxPnl = maximum(opt[:, posPnl])
    newOpt = opt[map(x -> (x==maxPnl), opt[:, 3]), :]

    d = load("data/computed/data.jld")["data"]
    d[split(asset, ".")[1]] = Dict(
                               "long"  => Statistics.mean(newOpt[:, posLong]),
                               "short" => Statistics.mean(newOpt[:, posShort]),
                               "pnl"   => Statistics.mean(newOpt[:, posPnl])
                                      )
    save("data/computed/data.jld", "data", d)

end

files = readdir(pathCoins)
for f in files
    marketMA(f)
end




#d = Dict(
#         asset => Dict(
#                       "long"  => Statistics.mean(newOpt[:, posLong]),
#                       "short" => Statistics.mean(newOpt[:, posShort]),
#                       "pnl"   => Statistics.mean(newOpt[:, posPnl])
#                      )
#        )


pnls = opt[:,posPnl][pnlMask...]
n = length(pnls)
[[true for _ in 1:n], [true for _ in 1:n], pnlMask...]

opt = opt[sortperm(opt[:, posPnl]), :]
opt = opt[idxFst:end, :]


#eval
opt_idx = findmax(strat.backtest.optimization[:,3])[2]
sets = Dict(zip(arg_names, strat.backtest.optimization[opt_idx, 1:2]))


#report
using Printf
Base.show(io::IO, f::Float64) = @printf(io, "%.2f", f)
ds = strat.universe.data["DOGE-BUSD"][:open]
cash=100
print("init value: "*string(cash))
trh = round((ds[end].values - ds[1].values)[1] * cash, digits=2)
print("long: "*string(trh)*", pct: "*string(round((trh/cash - 1)*100, digits=2))*"%")
opt = round(strat.backtest.optimization[opt_idx, 3], digits=2)
print("optim: "*string(opt)*", pct: "*string(round((opt/cash - 1)*100, digits=2))*"%")

using Plots
gr()
(x, y, z) = (strat.backtest.optimization[:,i] for i in 1:3)
surface(x, y, z)
