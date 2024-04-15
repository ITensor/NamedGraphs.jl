using Graphs: Graphs
using .GraphsExtensions: GraphsExtensions

struct NamedEdge{V} <: AbstractNamedEdge{V}
  src::V
  dst::V
  NamedEdge{V}(src::V, dst::V) where {V} = new{V}(src, dst)
end
NamedEdge(src::V, dst::V) where {V} = NamedEdge{V}(src, dst)
NamedEdge(src::S, dst::D) where {S,D} = NamedEdge{promote_type(S, D)}(src, dst)

GraphsExtensions.convert_vertextype(V::Type, ::Type{<:NamedEdge}) = NamedEdge{V}

Graphs.src(e::NamedEdge) = e.src
Graphs.dst(e::NamedEdge) = e.dst

NamedEdge{V}(e::NamedEdge{V}) where {V} = e
NamedEdge(e::NamedEdge) = e

NamedEdge{V}(e::AbstractNamedEdge) where {V} = NamedEdge{V}(e.src, e.dst)

Base.convert(E::Type{<:NamedEdge}, e::NamedEdge) = E(e)

NamedEdge(t::Tuple) = NamedEdge(t[1], t[2])
NamedEdge(p::Pair) = NamedEdge(p.first, p.second)
NamedEdge{V}(p::Pair) where {V} = NamedEdge{V}(p.first, p.second)
NamedEdge{V}(t::Tuple) where {V} = NamedEdge{V}(t[1], t[2])

# TODO: Define generic `set_vertices` in `GraphsExtensions`.
set_vertices(e::NamedEdge, src, dst) = NamedEdge(src, dst)
