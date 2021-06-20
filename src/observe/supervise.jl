function supervise(strat::Strategy;
                   arg_values::Union{Vector, Nothing}=nothing,
                   px_trade::Symbol=:Open,
                   px_close::Symbol=:Settle,
                   limit::Int)::String
    if isnothing(arg_values)
        arg_values = convert(Vector, strat.indicator.paramset.arg_defaults)
    end
    if isempty(strat.backtest.trades)
        all_trades = generate_trades(strat, arg_values=arg_values)
    else
        all_trades = strat.backtest.trades
    end

    for asset in strat.universe.assets
        trades = all_trades[asset].values
        N = size(trades, 1)

        cnt = 1
        action = false
        signal = "hold"
        while(cnt < limit)
            for (i,rule) in enumerate(strat.rules)
                if trades[N-cnt-1,i] != 0
                    signal = string(rule.action)
                    action = true; break
                end
            end
            if action break end
            cnt+=1
        end
        return signal
    end
end
