using Pkg; Pkg.activate(".")
using Strategems, Temporal, Indicators, Dates

function datasource(asset::String)::TS
    savedata_path = joinpath("/home/bane/ext_devs/hdd/candlestick_retriever/data/", "$asset")
    return Temporal.tsread(savedata_path, indextype=UInt64, format="yyyy-mm-dd HH:MM:SS")
end

    # define universe and gather data
asset = "AUTO-BTC.csv"
assets = [asset]
universe = Universe(assets)
universe = gather(assets, source=datasource)


arg_names = [:fastlimit, :slowlimit]
arg_ranges    = [0.01:0.01:0.99, 0.01:0.01:0.99]
arg_defaults = [0.24, 0.33]
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
res = supervise(strat, arg_values=arg_defaults, px_trade=:open, px_close=:close, limit=32)

bt = backtest(strat, px_trade=:open, px_close=:close)

