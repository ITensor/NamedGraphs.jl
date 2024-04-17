using Graphs: Graphs, AbstractEdge, dst, src
using .GraphsExtensions: GraphsExtensions, convert_vertextype, rename_vertices

abstract type AbstractNamedEdge{V} <: AbstractEdge{V} end

Base.eltype(::Type{<:AbstractNamedEdge{V}}) where {V} = V

Graphs.src(e::AbstractNamedEdge) = not_implemented()
Graphs.dst(e::AbstractNamedEdge) = not_implemented()

AbstractNamedEdge(e::AbstractNamedEdge) = e

function GraphsExtensions.convert_vertextype(
  ::Type{V}, E::Type{<:AbstractNamedEdge{V}}
) where {V}
  return E
end
function GraphsExtensions.convert_vertextype(::Type, E::Type{<:AbstractNamedEdge})
  return not_implemented()
end

function Base.show(io::IO, mime::MIME"text/plain", e::AbstractNamedEdge)
  show(io, src(e))
  print(io, " => ")
  show(io, dst(e))
  return nothing
end

Base.show(io::IO, edge::AbstractNamedEdge) = show(io, MIME"text/plain"(), edge)

# Conversions
Base.Pair(e::AbstractNamedEdge) = Pair(src(e), dst(e))
Base.Tuple(e::AbstractNamedEdge) = (src(e), dst(e))

# Convenience functions
Base.reverse(e::AbstractNamedEdge) = typeof(e)(dst(e), src(e))
function Base.:(==)(e1::AbstractNamedEdge, e2::AbstractNamedEdge)
  return (src(e1) == src(e2) && dst(e1) == dst(e2))
end
Base.hash(e::AbstractNamedEdge, h::UInt) = hash(src(e), hash(dst(e), h))

# TODO: Define generic version in `GraphsExtensions`.
# TODO: Define generic `set_vertices` in `GraphsExtensions`.
set_src(e::AbstractNamedEdge, src) = set_vertices(e, src, dst(e))
# TODO: Define generic version in `GraphsExtensions`.
# TODO: Define generic `set_vertices` in `GraphsExtensions`.
set_dst(e::AbstractNamedEdge, dst) = set_vertices(e, src(e), dst)

function GraphsExtensions.rename_vertices(f::Function, e::AbstractNamedEdge)
  # TODO: Define generic `set_vertices` in `GraphsExtensions`.
  return set_vertices(e, f(src(e)), f(dst(e)))
end

function GraphsExtensions.rename_vertices(e::AbstractEdge, name_map)
  return rename_vertices(v -> name_map[v], e)
end

function GraphsExtensions.rename_vertices(f::Function, e::AbstractEdge)
  return rename_vertices(f, AbstractNamedEdge(e))
end
