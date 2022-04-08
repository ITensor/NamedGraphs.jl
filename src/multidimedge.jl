# TODO: Generalize to `MultiDimEdge{V1,V2}`?
# The vertices could be different types...
struct MultiDimEdge{V<:Tuple} <: AbstractNamedEdge{V}
  src::V
  dst::V
end

src(e::MultiDimEdge) = e.src
dst(e::MultiDimEdge) = e.dst

MultiDimEdge{V}(e::MultiDimEdge{V}) where {V} = e

MultiDimEdge{V}(e::AbstractNamedEdge) where {V} = MultiDimEdge{V}(V(e.src), V(e.dst))

convert(E::Type{<:MultiDimEdge}, e::MultiDimEdge) = E(e)

# Tuple constructor that either keeps
# it as a Tuple or turns it into a Tuple.
_tuple(t::Tuple) = t
_tuple(x) = tuple(x)

MultiDimEdge(p::Pair) = MultiDimEdge(_tuple(p.first), _tuple(p.second))
MultiDimEdge{V}(p::Pair) where {V} = MultiDimEdge{V}(_tuple(p.first), _tuple(p.second))

# XXX: Is this a good idea? It clashes with Tuple vertices of MultiDimGraphs.
# MultiDimEdge(t::Tuple) = MultiDimEdge(t[1], t[2])
# MultiDimEdge{V}(t::Tuple) where {V} = MultiDimEdge(V(t[1]), V(t[2]))
