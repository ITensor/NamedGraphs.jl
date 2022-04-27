# TODO: Generalize to `NamedDimEdge{V1,V2}`?
# The vertices could be different types...
struct NamedDimEdge{V<:Tuple} <: AbstractNamedEdge{V}
  src::V
  dst::V
  function NamedDimEdge{V}(src::V, dst::V) where {V<:Tuple}
    return new{V}(src, dst)
  end
end

# Convert to a vertex of the graph type
# For example, for MultiDimNamedGraph, this does:
#
# to_vertex(graph, "X") # ("X",)
# to_vertex(graph, "X", 1) # ("X", 1)
# to_vertex(graph, ("X", 1)) # ("X", 1)
#
# For general graph types it is:
#
# to_vertex(graph, "X") # "X"
#
# TODO: Rename `tuple_convert` to `to_tuple`.
to_vertex(::Type{<:NamedDimEdge}, v...) = tuple_convert(v...)
to_vertex(e::NamedDimEdge, v...) = to_vertex(typeof(e), v...)

src(e::NamedDimEdge) = e.src
dst(e::NamedDimEdge) = e.dst

function NamedDimEdge(src, dst)
  return NamedDimEdge{Tuple}(to_vertex(NamedDimEdge, src), to_vertex(NamedDimEdge, dst))
end

function NamedDimEdge{V}(src, dst) where {V<:Tuple}
  return NamedDimEdge{V}(to_vertex(NamedDimEdge, src), to_vertex(NamedDimEdge, dst))
end

NamedDimEdge{V}(e::NamedDimEdge{V}) where {V<:Tuple} = e

NamedDimEdge(e::AbstractEdge) = NamedDimEdge(src(e), dst(e))
NamedDimEdge{V}(e::AbstractEdge) where {V<:Tuple} = NamedDimEdge{V}(src(e), dst(e))

convert(E::Type{<:NamedDimEdge}, e::NamedDimEdge) = E(e)

# Allows syntax like `dictionary[1 => 2]`.
convert(E::Type{<:NamedDimEdge}, e::Pair) = E(e)

NamedDimEdge(p::Pair) = NamedDimEdge(p.first, p.second)
NamedDimEdge{V}(p::Pair) where {V<:Tuple} = NamedDimEdge{V}(p.first, p.second)

# XXX: Is this a good idea? It clashes with Tuple vertices of NamedDimGraphs.
# NamedDimEdge(t::Tuple) = NamedDimEdge(t[1], t[2])
# NamedDimEdge{V}(t::Tuple) where {V} = NamedDimEdge(V(t[1]), V(t[2]))
