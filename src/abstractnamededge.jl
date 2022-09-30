abstract type AbstractNamedEdge{V} <: AbstractEdge{V} end

eltype(::Type{<:ET}) where {ET<:AbstractNamedEdge{T}} where {T} = T

src(e::AbstractNamedEdge) = not_implemented()
dst(e::AbstractNamedEdge) = not_implemented()

function show(io::IO, mime::MIME"text/plain", e::AbstractNamedEdge)
  show(io, src(e))
  print(io, " => ")
  show(io, dst(e))
  return nothing
end

show(io::IO, edge::AbstractNamedEdge) = show(io, MIME"text/plain"(), edge)

# Conversions
Pair(e::AbstractNamedEdge) = Pair(src(e), dst(e))
Tuple(e::AbstractNamedEdge) = (src(e), dst(e))

# Convenience functions
reverse(e::T) where {T<:AbstractNamedEdge} = T(dst(e), src(e))
function ==(e1::AbstractNamedEdge, e2::AbstractNamedEdge)
  return (src(e1) == src(e2) && dst(e1) == dst(e2))
end
hash(e::AbstractNamedEdge, h::UInt) = hash(src(e), hash(dst(e), h))

function rename_vertices(e::ET, name_map::Dictionary) where {ET<:AbstractNamedEdge}
  # strip type parameter to allow renaming to change the vertex type
  base_edge_type = Base.typename(ET).wrapper
  return base_edge_type(name_map[src(e)], name_map[dst(e)])
end
