module ModelParameters

export AbstractParameter, Parameter, getparameters,
    show, lower, upper, initial, value, constant, convert,
    +, *, -, /, <, isequal, isapprox, one, zero, norm, real, imag,
    isparameter, isfixed, reset!

import Base: +, *, -, /, \, ==, <, promote_rule, convert, push!, isequal,
    one, oneunit, zero, norm, real, imag, isapprox

abstract type AbstractParameter <: Number end

mutable struct Parameter{T<:Number} <: AbstractParameter
    value::T
    initial::T
    lower::T
    upper::T
    isfixed::Bool
    function Parameter(initial::T, lower::T, upper::T) where T<:Number
        if lower > upper
            throw(ArgumentError(
                "Invalid interval: lower bound is greater than upper bound."))
        elseif initial < lower || initial > upper
            throw(ArgumentError(
                "Initial value is outside the interval."))
        end
        isfixed = lower ≈ upper
        new{T}(initial, initial, lower, upper, isfixed)
    end
end

Parameter(v::T) where {T} = Parameter(v, typemin(T), typemax(T))
Parameter(lower, upper) = Parameter(lower + (upper - lower) / 2, lower, upper)
constant(v) = Parameter(v, v, v)

function push!(prm::Parameter, v)
    if v < lower(prm) || v > upper(prm)
        throw(ArgumentError("$v is outside the interval."))
    end
    prm.value = v
    return prm
end

function reset!(prm::Parameter)
    prm.value = prm.initial
    return prm
end

lower(par::Parameter) = par.lower
upper(par::Parameter) = par.upper
initial(par::Parameter) = par.initial
value(par::Parameter) = par.value
isfixed(prm::Parameter) = prm.isfixed
isparameter(prm::Parameter) = !prm.isfixed
one(::Type{Parameter{T}}) where {T} = constant(one(T))
oneunit(::Type{Parameter{T}}) where {T} = constant(oneunit(T))
zero(::Type{Parameter{T}}) where {T} = constant(zero(T))
one(::Parameter{T}) where {T} = constant(one(T))
oneunit(::Parameter{T}) where {T} = constant(oneunit(T))
zero(::Parameter{T}) where {T} = constant(zero(T))
norm(p::Parameter) = p.value
real(p::Parameter) = p.value
imag(p::Parameter) = 0.0

convert(::Type{Parameter{T}}, v::T) where T<:Number = constant(v)
promote_rule(::Type{Parameter{T}}, ::Type{T}) where T<:Number = Parameter{T}

Base.show(io::IO, prm::Parameter) = prm.isfixed ? print(io, prm.value) :
    print(io, prm.lower, " ≤ ", prm.value, " ≤ ", prm.upper)

(+)(lhs::Parameter, rhs::Parameter) = lhs.value + rhs.value
(-)(lhs::Parameter, rhs::Parameter) = lhs.value - rhs.value
(*)(lhs::Parameter, rhs::Parameter) = lhs.value * rhs.value
(/)(lhs::Parameter, rhs::Parameter) = lhs.value / rhs.value

(+)(lhs::Parameter, rhs::Number) = lhs.value + rhs
(+)(lhs::Number, rhs::Parameter) = lhs + rhs.value
(-)(lhs::Parameter, rhs::Number) = lhs.value - rhs
(-)(lhs::Number, rhs::Parameter) = lhs - rhs.value
(*)(lhs::Parameter, rhs::Number) = lhs.value * rhs
(*)(lhs::Number, rhs::Parameter) = lhs * rhs.value
(/)(lhs::Parameter, rhs::Number) = lhs.value / rhs
(/)(lhs::Number, rhs::Parameter) = lhs / rhs.value

isequal(lhs::Parameter, rhs::Parameter) = isequal(lhs.value, rhs.value)
isequal(lhs::Number, rhs::Parameter) = isequal(lhs, rhs.value)
isequal(lhs::Parameter, rhs::Number) = isequal(lhs.value, rhs)
==(lhs::Parameter, rhs::Parameter) = ==(lhs.value, rhs.value)
==(lhs::Number, rhs::Parameter) = ==(lhs, rhs.value)
==(lhs::Parameter, rhs::Number) = ==(lhs.value, rhs)
(<)(lhs::Parameter, rhs::Parameter) = lhs.value < rhs.value
(<)(lhs::Number, rhs::Parameter) = lhs < rhs.value
(<)(lhs::Parameter, rhs::Number) = lhs.value < rhs
isapprox(lhs::Parameter, rhs::Parameter) = isapprox(lhs.value, rhs.value)
isapprox(lhs::Number, rhs::Parameter) = isapprox(lhs, rhs.value)
isapprox(lhs::Parameter, rhs::Number) = isapprox(lhs.value, rhs)

const fun = (
    :abs2, :acosh, :acot, :acotd, :acoth, :acsc, :acscd, :acsch, :asec,
    :asecd, :asinh, :atan, :atand, :cbrt, :cos, :cosd, :cosh, :cot, :cotd,
    :coth, :csc, :cscd, :csch, :exp, :exp2, :expm1, :gamma, :inv, :lgamma,
    :log, :log10, :log1p, :log2, :sec, :secd, :sech, :sin, :sind, :sinh,
    :sqrt, :tan, :tand, :tanh, :acos, :acosd, :asech, :asin, :asind, :atanh,
)
for f in fun
    @eval begin
        import Base.$f
        export $f
        $f(par::Parameter) = $f(par.value)
    end
end

getparameters(data) = getparameters(Parameter[], data)
function getparameters(params, prm::Parameter)
    isparameter(prm) && push!(params, prm)
    return params
end
function getparameters(params, arr::AbstractArray)
    foreach(x -> getparameters(params, x), arr)
    return params
end
function getparameters(params, val)
    fields = fieldnames(val)
    foreach(x -> getparameters(params, getfield(val, x)), fields)
    return params
end

include("macros.jl")

end # module
