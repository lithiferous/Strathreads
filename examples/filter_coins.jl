root_dir = "../."
using Pkg; Pkg.activate(root_dir)
using CSV
using DataFrames
using Dates: Date, DateFormat, today, format
import DotEnv
using Redis
import Tables.namedtupleiterator

cfg = DotEnv.config(path="$root_dir/.env")


curDate = format(today(), DateFormat("yymmdd"))
#srcFile = "$(cfg["OUTPUT_DIR"])/$curDate.trade_info"
srcFile = "$(cfg["OUTPUT_DIR"])/211219.trade_info"
dstFile = "$(cfg["OUTPUT_DIR"])/$curDate.trade_list"
println(dstFile)

df = CSV.File(srcFile; comment="\n", delim=",", types=[String, Int32, Int32, Float64]) |> DataFrame

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

dfNoIdle = filterOnColumnNotLower(df, "trades_days_idle", 1 - 0.05)
dfUpTrades = filterOnColumnBigger(dfNoIdle, "trades_num_total", 1 - coef)

#conn = RedisConnection(password=cfg["REDIS_PWD"])

open(dstFile, "w") do io
    coin_vec = namedtupleiterator(dfUpTrades[:, "coin"]).x.x
    #l = ReentrantLock()
    Threads.@threads for c in coin_vec
        println(io, c)
        #try
        #finally
        #    unlock(l)
        #end
    end
#    set(conn, "$(curDate)_coins", coin_vec)
end
