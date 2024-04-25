using Dictionaries: Dictionaries, AbstractDictionary

abstract type AbstractOrderedDictionary{I,T} <: AbstractDictionary{I,T} end

# TODO: Better name for this?
ordered_indices(dict::AbstractOrderedDictionary) = error("Not implemented.")
# TODO: Better name for this?
parent_indices(dict::AbstractOrderedDictionary) = error("Not implemented.")

Base.@propagate_inbounds function Base.iterate(dict::AbstractOrderedDictionary, state...)
  return iterate(ordered_indices(dict), state...)
end
Base.length(dict::AbstractOrderedDictionary) = length(ordered_indices(dict))

# https://github.com/andyferris/Dictionaries.jl/tree/master?tab=readme-ov-file#implementing-the-token-interface-for-abstractindices
function Dictionaries.istokenizable(dict::AbstractOrderedDictionary)
  return Dictionaries.istokenizable(parent_indices(dict))
end
function Dictionaries.tokentype(dict::AbstractOrderedDictionary)
  return Dictionaries.tokentype(parent_indices(dict))
end
function Dictionaries.iteratetoken(dict::AbstractOrderedDictionary, state...)
  return Dictionaries.iteratetoken(parent_indices(dict), state...)
end
function Dictionaries.gettoken(dict::AbstractOrderedDictionary, key)
  return Dictionaries.gettoken(parent_indices(dict), key)
end
function Dictionaries.gettokenvalue(dict::AbstractOrderedDictionary, token)
  return Dictionaries.gettokenvalue(parent_indices(dict), token)
end
function Dictionaries.isinsertable(dict::AbstractOrderedDictionary)
  return Dictionaries.isinsertable(parent_indices(dict))
end
