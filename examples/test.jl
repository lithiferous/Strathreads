using Pkg; Pkg.activate(".")
using Strategems, Temporal, Indicators, Dates

# define universe and gather data
assets = ["EOS-USDT"]
#assets = ["CME_CL1"]
universe = Universe(assets)
function datasource(asset::String)::TS
    savedata_path = joinpath("/home/bane/projects/julia/Strategems.jl", "data", "test", "$asset.csv")
    return Temporal.tsread(savedata_path, indextype=DateTime)
end
gather!(universe, source=datasource)

# define indicators and parameter space
arg_names = [:fastlimit, :slowlimit]
arg_defaults = [0.5, 0.05]
arg_ranges = [0.01:0.01:0.99, 0.01:0.01:0.99]
paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
f(x; args...) = Indicators.mama(x; args...)
indicator = Indicator(f, paramset)

# define signals that will trigger trading decisions
siglong = @signal MAMA ↑ FAMA
sigshort = @signal MAMA ↓ FAMA
sigexit = @signal MAMA == FAMA

# define the trading rules
cash = 1000
longrule = @rule siglong → long cash
shortrule = @rule sigshort → short cash
exitrule = @rule sigexit → liquidate 1.0
rules = (longrule, shortrule, exitrule)

# run strategy
strat = Strategy(universe, indicator, rules)
backtest!(strat, px_trade=:open, px_close=:close, verbose=true)
optimize!(strat, px_trade=:open, px_close=:close)

#eval
opt_idx = findmax(strat.backtest.optimization[:,3])[2]
sets = Dict(zip(arg_names, strat.backtest.optimization[opt_idx, 1:2]))

#report
using Printf
Base.show(io::IO, f::Float64) = @printf(io, "%.2f", f)
ds = strat.universe.data["EOS-USDT"][:open]
print("init value: "*string(cash))
trh = round((ds[end].values - ds[1].values)[1] * cash, digits=2)
print("long: "*string(trh)*", pct: "*string(round((trh/cash - 1)*100, digits=2))*"%")
opt = round(strat.backtest.optimization[opt_idx, 3], digits=2)
print("optim: "*string(opt)*", pct: "*string(round((opt/cash - 1)*100, digits=2))*"%")

using Plots
gr()
(x, y, z) = (strat.backtest.optimization[:,i] for i in 1:3)
surface(x, y, z)
