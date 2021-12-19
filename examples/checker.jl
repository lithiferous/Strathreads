using Pkg; Pkg.activate(".")
using CSV
using DataFrames
using Dates: Date, DateFormat, today, format
import Tables.namedtupleiterator

curDate = format(today(), DateFormat("yyyymmdd"))
srcFile = "$curDate.filtered"
dstFile = "$curDate.candies"

df = CSV.File(srcFile; comment="\n") |> DataFrame
coef = 0.30 # how many days allowed percentage-wise to have absent trading activity
            # used as an upper bound quantile for the security to be traded

function filterOnColumnNotLower(df::DataFrame, col::String, coef::Float64)
    s_df = copy(df[:, col])
    maxN = maximum(s_df)
    mask = (s_df ./ maxN * 100) .<= coef
    copy(df[mask, :])
end

function filterOnColumnBigger(df::DataFrame, col::String, coef::Float64)
    s_df = copy(df[:, col])
    maxN = maximum(s_df)
    mask = (s_df ./ maxN * 100) .>= coef
    copy(df[mask, :])
end

dfNoIdle = filterOnColumnNotLower(df, "trades_days_idle", coef)
dfUpTrades = filterOnColumnBigger(dfNoIdle, "trades_num_total", 1 - coef)

open(dstFile, "w") do io
    coin_vec = namedtupleiterator(dfUpTrades[:, "coin"]).x.x
    for c in coin_vec
        println(io, c)
    end
end
