root_dir = "../."
using Pkg; Pkg.activate(root_dir)
import DotEnv

function main()
    cfg = DotEnv.config(path="$root_dir/.env")
    println(cfg["INPUT_DIR"])
    println(ARGS[end])
end
open("../data/opts.csv", "w") do io
    cols = join(["coin", "nslow","nfast","return"], ',')
    println(io, cols)
    for (key, value) in d
        println(io, join([key, join(value, ',')], ','))
    end
end

main()
