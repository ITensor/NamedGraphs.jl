using Dictionaries: Dictionaries, AbstractIndices, Dictionary

# Represents a [set](https://en.wikipedia.org/wiki/Set_(mathematics)) of indices
# `I` whose elements/members are ordered in a sequence such that each element can be
# associated with a position which is a positive integer
# (1-based [natural numbers](https://en.wikipedia.org/wiki/Natural_number))
# which can be accessed through ordinal indexing (`I[4th]`).
# Related to an (indexed family)[https://en.wikipedia.org/wiki/Indexed_family],
# [index set](https://en.wikipedia.org/wiki/Index_set), or
# [sequence](https://en.wikipedia.org/wiki/Sequence).
# In other words, it is a [bijection](https://en.wikipedia.org/wiki/Bijection)
# from a finite subset of 1-based natural numbers to a set of corresponding
# elements/members.
struct OrderedIndices{I} <: AbstractIndices{I}
  ordered_indices::Vector{I}
  index_positions::Dictionary{I,Int}
  function OrderedIndices{I}(indices) where {I}
    ordered_indices = collect(indices)
    index_positions = Dictionary{I,Int}(copy(ordered_indices), undef)
    for i in eachindex(ordered_indices)
      index_positions[ordered_indices[i]] = i
    end
    return new{I}(ordered_indices, index_positions)
  end
end
OrderedIndices(indices) = OrderedIndices{eltype(indices)}(indices)

OrderedIndices{I}(indices::OrderedIndices{I}) where {I} = copy(indices)

ordered_indices(indices::OrderedIndices) = getfield(indices, :ordered_indices)
# TODO: Better name for this?
index_positions(indices::OrderedIndices) = getfield(indices, :index_positions)
# TODO: Better name for this?
parent_indices(indices::OrderedIndices) = keys(index_positions(indices))

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
  if !haskey(index_positions(indices), key)
    return (false, 0)
  end
  return (true, index_positions(indices)[key])
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
  insert!(index_positions(indices), key, token)
  return (false, token)
end
function Dictionaries.deletetoken!(indices::OrderedIndices, token)
  len = length(indices)
  position = token
  index = ordered_indices(indices)[position]
  # Move the last vertex to the position of the deleted one.
  if position < len
    ordered_indices(indices)[position] = last(ordered_indices(indices))
  end
  last_index = pop!(ordered_indices(indices))
  delete!(index_positions(indices), index)
  if position < len
    index_positions(indices)[last_index] = position
  end
  return indices
end

# Circumvents https://github.com/andyferris/Dictionaries.jl/pull/140
function Base.map(f, indices::OrderedIndices)
  return OrderedDictionary(indices, map(f, ordered_indices(indices)))
end
