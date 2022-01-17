using Pkg; Pkg.activate("../.")
using CSV
using DataFrames
using Dates: Date, DateFormat, today, format
using Statistics

import DotEnv

cfg = DotEnv.config(path="$root_dir/.env")
pathCoins = cfg["INPUT_DIR"]
files = readdir(pathCoins)

function filterTradesNum(dst_file::String, files::Vector{String})
    open(dst_file, "a") do io
        cols = join(["coin", "trades_num_total","trades_days_idle","trades_num_mean"], ',')
        println(io, cols)
        l = ReentrantLock()
        Threads.@threads for f in files
            lock(l)
            try
                df = CSV.File(joinpath(pathCoins, f)) |> DataFrame
                coin = split(f, '.')[1]
                trades_num_total = sum(df.number_of_trades)
                trades_days_idle = sum(df.number_of_trades .== 0)
                trades_num_mean  = Statistics.mean(df.number_of_trades)
                row = join([coin, trades_num_total, trades_days_idle, trades_num_mean], ',')
                println(io, row)
            finally
                unlock(l)
            end
        end
    end
end

curDate = format(today(), DateFormat("yymmdd"))
dstFile = "$(cfg["OUTPUT_DIR"])/$curDate.trade_info"
println(dstFile)
filterTradesNum(dstFile, files)
