using Dictionaries: Dictionaries, AbstractIndices

abstract type AbstractOrderedIndices{I} <: AbstractIndices{I} end

# TODO: Better name for this?
ordered_indices(dict::AbstractOrderedIndices) = error("Not implemented.")
# TODO: Better name for this?
parent_indices(dict::AbstractOrderedIndices) = error("Not implemented.")

Base.@propagate_inbounds function Base.iterate(dict::AbstractOrderedIndices, state...)
  return iterate(ordered_indices(dict), state...)
end
Base.length(dict::AbstractOrderedIndices) = length(ordered_indices(dict))

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#implementing-the-token-interface-for-abstractindices
function Dictionaries.istokenizable(dict::AbstractOrderedIndices)
  return Dictionaries.istokenizable(parent_indices(dict))
end
function Dictionaries.tokentype(dict::AbstractOrderedIndices)
  return Dictionaries.tokentype(parent_indices(dict))
end
function Dictionaries.iteratetoken(dict::AbstractOrderedIndices, state...)
  return Dictionaries.iteratetoken(parent_indices(dict), state...)
end
function Dictionaries.iteratetoken_reverse(dict::AbstractOrderedIndices, state...)
  return Dictionaries.iteratetoken_reverse(parent_indices(dict), state...)
end
function Dictionaries.gettoken(dict::AbstractOrderedIndices, key)
  return Dictionaries.gettoken(parent_indices(dict), key)
end
function Dictionaries.gettokenvalue(dict::AbstractOrderedIndices, token)
  return Dictionaries.gettokenvalue(parent_indices(dict), token)
end
function Dictionaries.isinsertable(dict::AbstractOrderedIndices)
  return Dictionaries.isinsertable(parent_indices(dict))
end
