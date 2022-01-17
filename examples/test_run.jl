root_dir = "../."
using Pkg; Pkg.activate(root_dir)
using Strathreads, Temporal, Indicators, Dates
using DotEnv

pathCoins = "../data/test/"
outDir = "results"

_assets = Base.Filesystem.readdir("data/test/")
d = load("../data/opts.jld")
for c in _assets
    opts = d["macd"][c]
    assets = [c]
    
    universe = Universe(assets)
    function datasource(asset::String)::TS
        savedata_path = joinpath(pathCoins, asset)
        return Temporal.tsread(savedata_path, indextype=UInt64, format="yyyy-mm-dd HH:MM:SS")
    end
    universe = Universe(assets)
    universe = gather(assets, source=datasource)
    function fun(x::TS; args...)::TS
        close_prices = x[:close]
        macd_ma = macd(close_prices; args...)
        output = [close_prices macd_ma]
        #output.fields = [:close, :MACD] -> shit renames fields
        return output
    end
    arg_names = [:nfast, :nslow]
    arg_defaults = [trunc(Int, opts[1]),
                    trunc(Int, opts[2])]
    arg_ranges = [5:1:12, 15:1:35]
    paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
    indicator = Indicator(fun, paramset)
    
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
    tswrite(bt[c], joinpath(outDir, c))
end
