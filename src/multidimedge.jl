# TODO: Generalize to `MultiDimEdge{V1,V2}`?
# The vertices could be different types...
struct MultiDimEdge{V<:Tuple} <: AbstractNamedEdge{V}
  src::V
  dst::V
  function MultiDimEdge{V}(src::V, dst::V) where {V<:Tuple}
    return new{V}(src, dst)
  end
end

src(e::MultiDimEdge) = e.src
dst(e::MultiDimEdge) = e.dst

MultiDimEdge(src, dst) = MultiDimEdge{Tuple}(tuple_convert(src), tuple_convert(dst))
MultiDimEdge{V}(src, dst) where {V<:Tuple} = MultiDimEdge{V}(tuple_convert(src), tuple_convert(dst))

MultiDimEdge{V}(e::MultiDimEdge{V}) where {V<:Tuple} = e

MultiDimEdge(e::AbstractEdge) = MultiDimEdge(src(e), dst(e))
MultiDimEdge{V}(e::AbstractEdge) where {V<:Tuple} = MultiDimEdge{V}(src(e), dst(e))

convert(E::Type{<:MultiDimEdge}, e::MultiDimEdge) = E(e)

MultiDimEdge(p::Pair) = MultiDimEdge(p.first, p.second)
MultiDimEdge{V}(p::Pair) where {V<:Tuple} = MultiDimEdge{V}(p.first, p.second)

# XXX: Is this a good idea? It clashes with Tuple vertices of MultiDimGraphs.
# MultiDimEdge(t::Tuple) = MultiDimEdge(t[1], t[2])
# MultiDimEdge{V}(t::Tuple) where {V} = MultiDimEdge(V(t[1]), V(t[2]))
