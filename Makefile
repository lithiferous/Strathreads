#!make
include .env
export $(shell sed 's/=.*//' .env)

# creates list of raw coins for filtering with:
# - total number of trades
# - number of days idle
# - mean number of trades per day
get_trade_info:
	cd examples && julia -t ${JULIA_NUM_THREADS} get_trade_info.jl

# performs filtering on coef (0.3):
# - drops securities with idles days >= coef
# - drops securities with total number of trades >= 1- coef
filter:
	cd examples && julia -t ${JULIA_NUM_THREADS} filter_coins.jl

# calculates best historical macd params for trading
# and pushes values to redis with prefix: 'macd_security'
optimize:
	cd examples && julia -t ${JULIA_NUM_THREADS} optimizer.jl
