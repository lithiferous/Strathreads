using Pkg; Pkg.activate(".")
using CSV
using DataFrames
using Dates: Date, DateFormat, today, format

using Statistics

pathCoins = "../../../../python/candlestick_retriever/data/"
function filterTradesNum(file::String)
    open(file, "a") do io
        cols = join(["coin", "trades_num_total","trades_days_idle","trades_num_mean"], ',')
        println(io, cols)
        files = readdir(pathCoins)
        for f in files
            df = CSV.File(joinpath(pathCoins, f)) |> DataFrame
            coin = split(f, '.')[1]
            trades_num_total = sum(df.number_of_trades)
            trades_days_idle = sum(df.number_of_trades .== 0)
            trades_num_mean  = Statistics.mean(df.number_of_trades)
            row = join([coin, trades_num_total, trades_days_idle, trades_num_mean], ',')
            println(io, row)
        end
    end
end
curDate = format(today(), DateFormat("yyyymmdd"))
fileName = "$curDate.filtered"
println(fileName)
filterTradesNum(fileName)
