using Dictionaries: Dictionaries, AbstractIndices, Dictionary

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

OrderedIndices{I}(indices::OrderedIndices{I}) where {I} = copy(indices)

ordered_indices(indices::OrderedIndices) = getfield(indices, :ordered_indices)
# TODO: Better name for this?
index_ordinals(indices::OrderedIndices) = getfield(indices, :index_ordinals)
# TODO: Better name for this?
parent_indices(indices::OrderedIndices) = keys(index_ordinals(indices))

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#abstractindices
function Dictionaries.iterate(indices::OrderedIndices, state...)
  return Dictionaries.iterate(ordered_indices(indices), state...)
end
function Base.in(index::I, indices::OrderedIndices{I}) where {I}
  return in(index, parent_indices(indices))
end
Base.length(indices::OrderedIndices) = length(ordered_indices(indices))

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#implementing-the-token-interface-for-abstractindices
Dictionaries.istokenizable(indices::OrderedIndices) = true
Dictionaries.tokentype(indices::OrderedIndices) = Int
function Dictionaries.iteratetoken(indices::OrderedIndices, state...)
  return iterate(Base.OneTo(length(indices)), state...)
end
function Dictionaries.iteratetoken_reverse(indices::OrderedIndices, state...)
  return iterate(reverse(Base.OneTo(length(indices))), state...)
end
function Dictionaries.gettoken(indices::OrderedIndices, key)
  if !haskey(index_ordinals(indices), key)
    return (false, 0)
  end
  return (true, index_ordinals(indices)[key])
end
function Dictionaries.gettokenvalue(indices::OrderedIndices, token)
  return ordered_indices(indices)[token]
end

Dictionaries.isinsertable(indices::OrderedIndices) = true
function Dictionaries.gettoken!(indices::OrderedIndices{I}, key::I) where {I}
  (hadtoken, token) = Dictionaries.gettoken(indices, key)
  if hadtoken
    return (true, token)
  end
  push!(ordered_indices(indices), key)
  token = length(ordered_indices(indices))
  insert!(index_ordinals(indices), key, token)
  return (false, token)
end
function Dictionaries.deletetoken!(indices::OrderedIndices, token)
  len = length(indices)
  ordinal = token
  index = ordered_indices(indices)[ordinal]
  # Move the last vertex to the position of the deleted one.
  if ordinal < len
    ordered_indices(indices)[ordinal] = last(ordered_indices(indices))
  end
  last_index = pop!(ordered_indices(indices))
  delete!(index_ordinals(indices), index)
  if ordinal < len
    index_ordinals(indices)[last_index] = ordinal
  end
  return indices
end
