struct One <: Integer end
const 𝟏 = One()
Base.convert(type::Type{<:Number}, ::One) = one(type)
Base.promote_rule(type1::Type{One}, type2::Type{<:Number}) = type2
Base.:(*)(x::One, y::One) = 𝟏

# Needed for Julia 1.7.
Base.convert(::Type{One}, ::One) = One()

function Base.show(io::IO, ordinal::One)
    return print(io, "𝟏")
end
