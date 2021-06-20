
import Base: show

mutable struct Indicator
    fun::Function
    paramset::ParameterSet
    data::TS
    function Indicator(fun::Function, paramset::ParameterSet, data::TS)
        return new(fun, paramset, data)
    end
end

function Indicator(fun::Function, paramset::ParameterSet)
    return Indicator(fun, paramset, TS())
end

function calculate(indicator::Indicator, input::TS; arg_values::Vector)::TS
    return indicator.fun(input; generate_dict(indicator.paramset, arg_values)...)
end

# TODO: add information about the calculation function
function show(io::IO, indicator::Indicator)
    show(io, indicator.paramset)
end
