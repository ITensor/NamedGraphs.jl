module Keys
"""
Key{K}

A key (index) type, used for unambiguously identifying
an object as a key or index of an indexible object
`AbstractArray`, `AbstractDict`, etc.

Useful for nested structures of indices, for example:

```julia
[Key([1, 2]), [Key([3, 4]), Key([5, 6])]]
```

which could represent partitioning a set of vertices

```julia
[Key([1, 2]), Key([3, 4]), Key([5, 6])]
```
"""
struct Key{K}
    I::K
end
Key(I...) = Key(I)

Base.show(io::IO, I::Key) = print(io, "Key(", I.I, ")")

## For indexing into `AbstractArray`
# This allows linear indexing `A[Key(2)]`.
# Overload of `Base.to_index`.
Base.to_index(I::Key) = I.I

# This allows cartesian indexing `A[Key(CartesianIndex(1, 2))]`.
# Overload of `Base.to_indices`.
Base.to_indices(A::AbstractArray, I::Tuple{Key{<:CartesianIndex}}) = I[1].I.I

# This would allow syntax like `A[Key(1, 2)]`, should we support that?
# Overload of `Base.to_indices`.
# to_indices(A::AbstractArray, I::Tuple{Key}) = I[1].I

Base.getindex(d::AbstractDict, I::Key) = d[I.I]

# Fix ambiguity error with Base
Base.getindex(d::Dict, I::Key) = d[I.I]

using Dictionaries: AbstractDictionary
Base.getindex(d::AbstractDictionary, I::Key) = d[I.I]
end
