struct OrdinalSuffixedInteger{T <: Integer} <: Integer
    cardinal::T
    function OrdinalSuffixedInteger{T}(cardinal::Integer) where {T <: Integer}
        cardinal ≥ 0 || throw(ArgumentError("ordinal must be > 0"))
        return new{T}(cardinal)
    end
end
function OrdinalSuffixedInteger(cardinal::Integer)
    return OrdinalSuffixedInteger{typeof(cardinal)}(cardinal)
end
function OrdinalSuffixedInteger{T}(ordinal::OrdinalSuffixedInteger) where {T <: Integer}
    return OrdinalSuffixedInteger{T}(cardinal(ordinal))
end

cardinal(ordinal::OrdinalSuffixedInteger) = getfield(ordinal, :cardinal)
function cardinal_type(ordinal_type::Type{<:OrdinalSuffixedInteger})
    return fieldtype(ordinal_type, :cardinal)
end

const th = OrdinalSuffixedInteger(𝟏)
const st = th
const nd = th
const rd = th

function Base.widen(ordinal_type::Type{<:OrdinalSuffixedInteger})
    return OrdinalSuffixedInteger{widen(cardinal_type(ordinal_type))}
end

Base.Int(ordinal::OrdinalSuffixedInteger) = Int(cardinal(ordinal))

function Base.:(*)(a::OrdinalSuffixedInteger, b::Integer)
    return OrdinalSuffixedInteger(cardinal(a) * b)
end
function Base.:(*)(a::Integer, b::OrdinalSuffixedInteger)
    return OrdinalSuffixedInteger(a * cardinal(b))
end
function Base.:(:)(
        start::OrdinalSuffixedInteger{T}, stop::OrdinalSuffixedInteger{T}
    ) where {T <: Integer}
    return UnitRange{OrdinalSuffixedInteger{T}}(start, stop)
end

function Base.:(*)(a::OrdinalSuffixedInteger, b::OrdinalSuffixedInteger)
    return (cardinal(a) * cardinal(b)) * th
end
function Base.:(+)(a::OrdinalSuffixedInteger, b::OrdinalSuffixedInteger)
    return (cardinal(a) + cardinal(b)) * th
end
function Base.:(+)(a::OrdinalSuffixedInteger, b::Integer)
    return a + b * th
end
function Base.:(+)(a::Integer, b::OrdinalSuffixedInteger)
    return a * th + b
end
function Base.:(-)(a::OrdinalSuffixedInteger, b::OrdinalSuffixedInteger)
    return (cardinal(a) - cardinal(b)) * th
end
function Base.:(-)(a::OrdinalSuffixedInteger, b::Integer)
    return a - b * th
end
function Base.:(-)(a::Integer, b::OrdinalSuffixedInteger)
    return a * th - b
end

function Base.:(:)(a::Integer, b::OrdinalSuffixedInteger)
    return (a * th):b
end

function Base.:(<)(a::OrdinalSuffixedInteger, b::OrdinalSuffixedInteger)
    return (cardinal(a) < cardinal(b))
end
Base.:(<)(a::OrdinalSuffixedInteger, b::Integer) = (a < b * th)
Base.:(<)(a::Integer, b::OrdinalSuffixedInteger) = (a * th < b)
function Base.:(<=)(a::OrdinalSuffixedInteger, b::OrdinalSuffixedInteger)
    return (cardinal(a) <= cardinal(b))
end
Base.:(<=)(a::OrdinalSuffixedInteger, b::Integer) = (a <= b * th)
Base.:(<=)(a::Integer, b::OrdinalSuffixedInteger) = (a * th <= b)

function Broadcast.broadcasted(
        ::Broadcast.DefaultArrayStyle{1},
        ::typeof(*),
        r::UnitRange,
        t::OrdinalSuffixedInteger{One},
    )
    return (first(r) * t):(last(r) * t)
end
function Broadcast.broadcasted(
        ::Broadcast.DefaultArrayStyle{1},
        ::typeof(*),
        r::Base.OneTo,
        t::OrdinalSuffixedInteger{One},
    )
    return Base.OneTo(last(r) * t)
end

function Base.show(io::IO, ordinal::OrdinalSuffixedInteger)
    n = cardinal(ordinal)
    m = n % 10
    if m == 1
        return print(io, n, n == 11 ? "th" : "st")
    elseif m == 2
        return print(io, n, n == 12 ? "th" : "nd")
    elseif m == 3
        return print(io, n, n == 13 ? "th" : "rd")
    end
    return print(io, n, "th")
end
