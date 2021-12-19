#=
Type and methods to simplify data filtering of tradable assets
=#

using CSV
using DataFrames
using Statistics
using Dates: Date, DateFormat, today, format

curDate = format(today(), DateFormat("yyyymmdd"))

fileName = "$curDate.filtered"
#using HDF5, JLD

#function writer(file::String, sep::Char)
#    d = load("data/computed/data.jld")["data"]
#    open(file, "a") do io
#        cols = join(["coin", "long", "short", "pnl"], sep)
#        println(io, cols)
#        for (i, (k, v)) in enumerate(d)
#            t = join([k, v["long"], v["short"], v["pnl"]], sep)
#            println(io, t)
#        end
#    end
#end

#fileo = "data/computed/pnl.csv"
#writer(fileo, ',')

#df = CSV.File(fileo) |> DataFrame
#max_trades = maximum(df.trades_days_idle)
#mask = df.trades_days_idle ./ max_trades * 100 .> 10
#df[mask, :]
#coin = "AION-ETH.csv"
#df = CSV.File(joinpath(pathCoins, coin)) |> DataFrame
#using Dates
#insertcols!(df, 1, :open_datetime => map(x->(unix2datetime(x/1000)), df.open_time))
#
#
#using CSV
#using DataFrames
#using Statistics
##pathCoins = "/home/bane/ext_devs/hdd/candlestick_retriever/data/"
#pathCoins = "../../../python/candlestick_retriever/data/"
#function filterTradesNum(file::String)
#    open(file, "a") do io
#        cols = join(["coin", "trades_num_total","trades_days_idle","trades_num_mean"], ',')
#        println(io, cols)
#        files = readdir(pathCoins)
#        for f in files
#            df = CSV.File(joinpath(pathCoins, f)) |> DataFrame
#            coin = split(f, '.')[1]
#            trades_num_total = sum(df.number_of_trades)
#            trades_days_idle = sum(df.number_of_trades .== 0)
#            trades_num_mean  = Statistics.mean(df.number_of_trades)
#            row = join([coin, trades_num_total, trades_days_idle, trades_num_mean], ',')
#            println(io, row)
#        end
#    end
#end
#
#fileName = "2011111.filtered" 
#
#filterTradesNum(fileName)
#df = CSV.File(fileName)
#max_trades = maximum(df.trades_days_idle)
#println(max_trades)
#mask = df.trades_days_idle ./ max_trades * 100 .> 10
#df[mask, :]
#using HDF5, JLD



