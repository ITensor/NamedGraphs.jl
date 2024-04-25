module OrdinalIndexedDictionaries
using Dictionaries: Dictionaries, AbstractIndices, Dictionary, gettoken

struct OrderedIndices{I} <: AbstractIndices{I}
  ordered_indices::Vector{I}
  index_ordinals::Dictionary{I,Int}
  function OrderedIndices{I}(indices) where {I}
    ordered_indices = collect(indices)
    index_ordinals = Dictionary{I,Int}(copy(ordered_indices), undef)
    for i in eachindex(ordered_indices)
      index_ordinals[ordered_indices[i]] = i
    end
    return new{I}(ordered_indices, index_ordinals)
  end
end
OrderedIndices(indices) = OrderedIndices{eltype(indices)}(indices)

Base.@propagate_inbounds function Base.iterate(indices::OrderedIndices, state...)
  return iterate(indices.ordered_indices, state...)
end
Base.length(indices::OrderedIndices) = length(indices.ordered_indices)

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#implementing-the-token-interface-for-abstractindices
Dictionaries.istokenizable(indices::OrderedIndices) = true
Dictionaries.tokentype(indices::OrderedIndices) = Int
function Dictionaries.iteratetoken(indices::OrderedIndices, state...)
  return Dictionaries.iteratetoken(keys(indices.index_ordinals), state...)
end
function Dictionaries.gettoken(indices::OrderedIndices, key)
  return Dictionaries.gettoken(keys(indices.index_ordinals), key)
end
function Dictionaries.gettokenvalue(indices::OrderedIndices, token)
  return Dictionaries.gettokenvalue(keys(indices.index_ordinals), token)
end
Dictionaries.isinsertable(indices::OrderedIndices) = true
function Dictionaries.gettoken!(indices::OrderedIndices{I}, key::I) where {I}
  (hadtoken, token) = Dictionaries.gettoken!(indices.index_ordinals, key)
  Dictionaries.settokenvalue!(
    indices.index_ordinals, token, length(indices.ordered_indices)
  )
  if !hadtoken
    push!(indices.ordered_indices, key)
  end
  return (hadtoken, token)
end
function Dictionaries.deletetoken!(indices::OrderedIndices, token)
  index = Dictionaries.gettokenvalue(keys(indices.index_ordinals), token)
  ordinal = Dictionaries.gettokenvalue(indices.index_ordinals, token)
  # Move the last vertex to the position of the deleted one.
  indices.ordered_indices[ordinal] = last(indices.ordered_indices)
  last_index = pop!(indices.ordered_indices)
  Dictionaries.deletetoken!(indices.index_ordinals, token)
  indices.index_ordinals[last_index] = ordinal
  return indices
end

using ..OrdinalIndexing: OrdinalSuffixedInteger, th
Base.@propagate_inbounds function Base.getindex(
  indices::OrderedIndices, i::OrdinalSuffixedInteger
)
  return indices.ordered_indices[Integer(i)]
end
Base.@propagate_inbounds function Base.setindex!(
  indices::OrderedIndices, value, index::OrdinalSuffixedInteger
)
  old_value = indices.ordered_indices[Integer(index)]
  indices.ordered_indices[Integer(index)] = value
  delete!(indices.index_ordinals, old_value)
  set!(indices.index_ordinals, value, Integer(index))
  return indices
end
each_ordinal_index(indices::OrderedIndices) = (Base.OneTo(length(indices))) * th
end
