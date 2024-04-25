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
function Dictionaries.istokenizable(indices::OrderedIndices)
  return Dictionaries.istokenizable(parent_indices(indices))
end
function Dictionaries.tokentype(indices::OrderedIndices)
  return Dictionaries.tokentype(parent_indices(indices))
end
function Dictionaries.iteratetoken(indices::OrderedIndices, state...)
  return Dictionaries.iteratetoken(parent_indices(indices), state...)
end
function Dictionaries.iteratetoken_reverse(indices::OrderedIndices, state...)
  return Dictionaries.iteratetoken_reverse(parent_indices(indices), state...)
end
function Dictionaries.gettoken(dict::OrderedIndices, key)
  return Dictionaries.gettoken(parent_indices(dict), key)
end
function Dictionaries.gettokenvalue(dict::OrderedIndices, token)
  return Dictionaries.gettokenvalue(parent_indices(dict), token)
end

function Dictionaries.isinsertable(dict::OrderedIndices)
  return Dictionaries.isinsertable(parent_indices(dict))
end
function Dictionaries.gettoken!(indices::OrderedIndices{I}, key::I) where {I}
  (hadtoken, token) = Dictionaries.gettoken!(index_ordinals(indices), key)
  Dictionaries.settokenvalue!(
    index_ordinals(indices),
    token,
    length(ordered_indices(indices)) + oneunit(length(ordered_indices(indices))),
  )
  if !hadtoken
    push!(ordered_indices(indices), key)
  end
  return (hadtoken, token)
end
function Dictionaries.deletetoken!(inds::OrderedIndices, token)
  len = length(inds)
  index = Dictionaries.gettokenvalue(parent_indices(inds), token)
  ordinal = Dictionaries.gettokenvalue(index_ordinals(inds), token)
  # Move the last vertex to the position of the deleted one.
  if ordinal < len
    ordered_indices(inds)[ordinal] = last(ordered_indices(inds))
  end
  last_index = pop!(ordered_indices(inds))
  Dictionaries.deletetoken!(index_ordinals(inds), token)
  if ordinal < len
    index_ordinals(inds)[last_index] = ordinal
  end
  return inds
end
