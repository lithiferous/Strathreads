using Pkg; Pkg.activate(".")
using Strathreads, Temporal, Indicators, Dates

pathCoins = "../../../../python/candlestick_retriever/data/"
assets = ["EOS-USDT"]
universe = Universe(assets)
function datasource(asset::String)::TS
    savedata_path = joinpath(pathCoins, "$asset.csv")
    return Temporal.tsread(savedata_path, indextype=UInt64, format="yyyy-mm-dd HH:MM:SS")
end
universe = Universe(assets)
universe = gather(assets, source=datasource)

# define indicators and parameter space
function fun(x::TS; args...)::TS
    close_prices = x[:close]
    macd_ma = macd(close_prices; args...)
    output = [close_prices macd_ma]
    #output.fields = [:close, :MACD] -> shit renames fields
    return output
end
arg_names = [:nfast, :nslow]
arg_defaults = [12, 26]
arg_ranges = [5:1:12, 15:1:35]
paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
indicator = Indicator(fun, paramset)

# define signals that will trigger trading decisions
siglong = @signal  MACD ↑ Signal
sigexit = @signal MACD == Signal
sigshort = @signal MACD ↓ Signal

# define the trading rules
longrule = @rule siglong → long 100
shortrule = @rule sigshort → short 100
exitrule = @rule sigexit → liquidate 1.0
rules = (longrule, shortrule, exitrule)


# run strategy
strat = Strategy(universe, indicator, rules)
bt = backtest(strat, px_trade=:open, px_close=:close, verbose=true)
opt = optimize(strat, px_trade=:open, px_close=:close)

##visualize
#using Plots
#gr()
#(x, y, z) = (opt[:,i] for i in 1:3)
#surface(x, y, z)

#eval best
opt_idx = findmax(opt[:,3])[2]
sets = Dict(zip(arg_names, opt[opt_idx, 1:2]))
opt[opt_idx, :]
