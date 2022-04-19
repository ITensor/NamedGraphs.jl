# TODO: Generalize to `NamedDimEdge{V1,V2}`?
# The vertices could be different types...
struct NamedDimEdge{V<:Tuple} <: AbstractNamedEdge{V}
  src::V
  dst::V
  function NamedDimEdge{V}(src::V, dst::V) where {V<:Tuple}
    return new{V}(src, dst)
  end
end

src(e::NamedDimEdge) = e.src
dst(e::NamedDimEdge) = e.dst

NamedDimEdge(src, dst) = NamedDimEdge{Tuple}(tuple_convert(src), tuple_convert(dst))
function NamedDimEdge{V}(src, dst) where {V<:Tuple}
  return NamedDimEdge{V}(tuple_convert(src), tuple_convert(dst))
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
