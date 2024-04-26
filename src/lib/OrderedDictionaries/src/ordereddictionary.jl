using Dictionaries: AbstractDictionary

struct OrderedDictionary{I,T} <: AbstractDictionary{I,T}
  indices::OrderedIndices{I}
  values::Vector{T}
  global function _OrderedDictionary(inds::OrderedIndices, values::Vector)
    @assert length(values) == length(inds)
    return new{eltype(inds),eltype(values)}(inds, values)
  end
end

function OrderedDictionary(indices::OrderedIndices, values::Vector)
  return _OrderedDictionary(indices, values)
end

function OrderedDictionary(indices, values)
  return OrderedDictionary(OrderedIndices(indices), Vector(values))
end

Base.values(dict::OrderedDictionary) = getfield(dict, :values)

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#abstractdictionary
Base.keys(dict::OrderedDictionary) = getfield(dict, :indices)

ordered_indices(dict::OrderedDictionary) = ordered_indices(keys(dict))

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#implementing-the-token-interface-for-abstractdictionary
Dictionaries.istokenizable(dict::OrderedDictionary) = Dictionaries.istokenizable(keys(dict))
Base.@propagate_inbounds function Dictionaries.gettokenvalue(
  dict::OrderedDictionary, token::Int
)
  return values(dict)[token]
end
function Dictionaries.istokenassigned(dict::OrderedDictionary, token::Int)
  return isassigned(values(dict), token)
end

Dictionaries.issettable(dict::OrderedDictionary) = true
Base.@propagate_inbounds function Dictionaries.settokenvalue!(
  dict::OrderedDictionary{<:Any,T}, token::Int, value::T
) where {T}
  values(dict)[token] = value
  return dict
end

Dictionaries.isinsertable(dict::OrderedDictionary) = true
Dictionaries.gettoken!(dict::OrderedDictionary, index) = error()
Dictionaries.deletetoken!(dict::OrderedDictionary, token) = error()

function Base.similar(indices::OrderedIndices, type::Type)
  return OrderedDictionary(indices, Vector{type}(undef, length(indices)))
end

# Circumvents https://github.com/andyferris/Dictionaries.jl/pull/140
function Base.map(f, dict::OrderedDictionary)
  return OrderedDictionary(keys(dict), map(f, values(dict)))
end
