struct NamedEdge{V} <: AbstractNamedEdge{V}
  src::V
  dst::V
end

src(e::NamedEdge) = e.src
dst(e::NamedEdge) = e.dst

NamedEdge{V}(e::NamedEdge{V}) where {V} = e

NamedEdge{V}(e::AbstractNamedEdge) where {V} = NamedEdge{V}(V(e.src), V(e.dst))

convert(E::Type{<:NamedEdge}, e::NamedEdge) = E(e)

NamedEdge(t::Tuple) = NamedEdge(t[1], t[2])
NamedEdge(p::Pair) = NamedEdge(p.first, p.second)
NamedEdge{V}(p::Pair) where {V} = NamedEdge(V(p.first), V(p.second))
NamedEdge{V}(t::Tuple) where {V} = NamedEdge(V(t[1]), V(t[2]))

set_vertices(e::NamedEdge, src, dst) = NamedEdge(src, dst)
