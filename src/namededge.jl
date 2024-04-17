using Graphs: Graphs
using .GraphsExtensions: GraphsExtensions

struct NamedEdge{V} <: AbstractNamedEdge{V}
  src::V
  dst::V
  NamedEdge{V}(src, dst) where {V} = new{V}(src, dst)
end
NamedEdge(src::V, dst::V) where {V} = NamedEdge{V}(src, dst)
NamedEdge(src, dst) = NamedEdge{promote_type(typeof(src), typeof(dst))}(src, dst)

function GraphsExtensions.convert_vertextype(vertextype::Type, ::Type{<:NamedEdge})
  return NamedEdge{vertextype}
end

Graphs.src(e::NamedEdge) = e.src
Graphs.dst(e::NamedEdge) = e.dst

NamedEdge{V}(e::NamedEdge{V}) where {V} = e
NamedEdge(e::NamedEdge) = e

NamedEdge{V}(e::AbstractEdge) where {V} = NamedEdge{V}(src(e), dst(e))
NamedEdge(e::AbstractEdge) = NamedEdge(src(e), dst(e))

AbstractNamedEdge(e::AbstractEdge) = NamedEdge(e)

Base.convert(edgetype::Type{<:NamedEdge}, e::AbstractEdge) = edgetype(e)

NamedEdge(p::Tuple) = NamedEdge(p...)
NamedEdge(p::Pair) = NamedEdge(p...)
NamedEdge{V}(p::Pair) where {V} = NamedEdge{V}(p...)
NamedEdge{V}(p::Tuple) where {V} = NamedEdge{V}(p...)

# TODO: Define generic `set_vertices` in `GraphsExtensions`.
set_vertices(e::NamedEdge, src, dst) = NamedEdge(src, dst)
