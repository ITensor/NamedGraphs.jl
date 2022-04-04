struct NamedEdge{V} <: AbstractNamedEdge{V}
  src::V
  dst::V
end

src(e::NamedEdge) = e.src
dst(e::NamedEdge) = e.dst

NamedEdge{T}(e::NamedEdge{T}) where {T} = e

NamedEdge{T}(e::AbstractNamedEdge) where {T} = NamedEdge{T}(T(e.src), T(e.dst))

NamedEdge(t::Tuple) = NamedEdge(t[1], t[2])
NamedEdge(p::Pair) = NamedEdge(p.first, p.second)
NamedEdge{T}(p::Pair) where {T} = NamedEdge(T(p.first), T(p.second))
NamedEdge{T}(t::Tuple) where {T} = NamedEdge(T(t[1]), T(t[2]))
