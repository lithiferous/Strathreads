using Strategems, Temporal, Indicators, Plots

# define universe and gather data
assets = ["EOD/AAPL", "EOD/MCD", "EOD/JPM", "EOD/MMM", "EOD/XOM"]
universe = Universe(assets)

function datasource(asset::String; save_downloads::Bool=true)::TS
    path = joinpath(dirname(pathof(Strategems)), "..", "data", "test", "$asset.csv")
    if isfile(path)
        return Temporal.tsread(path)
    else
        X = quandl(asset)
        if save_downloads
            if !isdir(dirname(path))
                mkdir(dirname(path))
            end
            Temporal.tswrite(X, path)
        end
        return X
    end
end

gather!(universe, source=datasource)

# define indicator and parameter space
function fun(x::TS; args...)::TS
    close_prices = x[:Adj_Close]
    moving_average = sma(close_prices; args...)
    output = [close_prices moving_average]
    output.fields = [:Adj_Close, :MA]
    return output
end
indicator = Indicator(fun, ParameterSet([:n], [50], [10:5:200]))

# define signals
longsignal = @signal Adj_Close ↑ MA
shortsignal = @signal Adj_Close ↓ MA

# define trading rules
longrule = @rule longsignal → buy 100
shortrule = @rule shortsignal → liquidate 100

# construct and test the strategy
strat = Strategy(universe, indicator, (longrule, shortrule))

backtest!(strat, px_trade=:Adj_Open, px_close=:Adj_Close)
weights, holdings, values, profits = summarize_results(strat)

plot(holdings, layout=(length(assets),1), color=(1:length(assets))')
plot(weights[:,1:length(assets)], layout=(length(assets),1), color=(1:length(assets))')
plot(cumsum(profits), layout=(fld(length(assets)+1,2),2), color=(1:length(assets)+1)')
