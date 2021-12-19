# creates list of coins for filtering with:
# - total number of trades
# - number of days idle
# - mean number of trades per day
filter:
	julia -t 14 examples/filter.jl

# performs filtering on coef (0.3):
# - drops securities with idles days >= coef
# - drops securities with total number of trades >= 1- coef
check:
	julia -t 14 examples/checker.jl

# calculates best historical macd params for trading
# and pushes values to redis with prefix: 'macd_security'
optimize:
	julia -t 14 examples/optimizer.jl
