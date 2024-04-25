using Dictionaries: Dictionaries, AbstractIndices, Dictionary

struct OrderedIndices{I} <: AbstractOrderedIndices{I}
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
