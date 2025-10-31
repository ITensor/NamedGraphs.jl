using Dictionaries: Dictionary
using Graphs: Graphs, AbstractEdge, AbstractEdgeIter, dst, edgetype, has_edge, has_vertex,
    ne, neighbors, src, vertices
using ..NamedGraphs: NamedGraphs, AbstractNamedEdge, AbstractNamedGraph, NamedEdge,
    PositionGraphView

# Helper functions
oneelement_tuple(j::Int, N) = ntuple(i -> i == j ? 1 : 0, N)

# Minimal interface functions
ishypertorus(g) = error("Not implemented.")
grid_size(g) = error("Not implemented.")
grid_ndims(G::Type) = error("Not implemented")
is_directed_grid(G::Type) = false

# Edge iterator
struct NamedGridEdgeIter{G} <: AbstractEdgeIter
    g::G
end
Base.eltype(::Type{NamedGridEdgeIter{G}}) where {G} = edgetype(G)

function grid_edge_generator(g)
    return (edgetype(g)(s, d) for s in vertices(g) for d in plus_neighbors(g, s))
end
function Base.iterate(eiter::NamedGridEdgeIter{G}) where {G}
    gen = grid_edge_generator(eiter.g)
    initial = iterate(gen)
    isnothing(initial) && return nothing
    edge, state = initial
    return edge, (gen, state)
end
function Base.iterate(eiter::NamedGridEdgeIter, (gen, state))
    result = iterate(gen, state)
    isnothing(result) && return nothing
    edge, newstate = result
    return edge, (gen, newstate)
end
Base.length(eiter::NamedGridEdgeIter) = ne(eiter.g)
Base.in(e, eiter::NamedGridEdgeIter) = has_edge(eiter.g, e)
Base.show(io::IO, eiter::NamedGridEdgeIter) = show(io, collect(eiter))

# Derived interface functions
grid_length(g) = prod(grid_size(g))
grid_ndims(g) = length(grid_size(g))
nv_grid(g) = grid_length(g)
vertices_grid(g) = Tuple.(CartesianIndices(grid_size(g)))
has_vertex_grid(g, v) = CartesianIndex(v) in CartesianIndices(grid_size(g))
add_vertex_grid!(g, v) = error("Can't add vertices to immutable graph.")
rem_vertex_grid!(g, v) = error("Can't remove vertices to immutable graph.")
edgetype_grid(G::Type) = NamedEdge{NTuple{grid_ndims(G), Int}}
edgetype_grid(g) = NamedEdge{NTuple{grid_ndims(g), Int}}
function ne_grid(g)
    ne_g = grid_ndims(g) * grid_length(g)
    if !ishypertorus(g)
        ne_g -= sum(sᵢ -> div(grid_length(g), sᵢ), grid_size(g))
    end
    return ne_g
end
function plus_neighbors(g, v)
    ns = [v .+ oneelement_tuple(d, length(v)) for d in Base.OneTo(grid_ndims(g))]
    if !ishypertorus(g)
        ns = filter(ns) do n
            return CartesianIndex(n) in CartesianIndices(grid_size(g))
        end
    end
    return ns
end
function minus_neighbors(g, v)
    ns = [v .- oneelement_tuple(d, length(v)) for d in 1:grid_ndims(g)]
    if !ishypertorus(g)
        ns = filter(ns) do n
            return CartesianIndex(n) in CartesianIndices(grid_size(g))
        end
    end
    return ns
end
neighbors_grid(g, v) = [minus_neighbors(g, v); plus_neighbors(g, v)]
function has_edge_grid(g, s, d)
    has_vertex(g, s) || return false
    has_vertex(g, d) || return false
    return d in neighbors(g, s)
end
has_edge_grid(g, e) = has_edge(g, edgetype(g)(e))
has_edge_grid(g, e::AbstractEdge) = has_edge(g, src(e), dst(e))
add_edge_grid!(g, s, d) = error("Can't add edges to immutable graph.")
add_edge_grid!(g, e) = add_edge_grid!(g, edgetype(g)(e))
add_edge_grid!(g, e::AbstractEdge) = add_edge_grid!(g, src(e), dst(e))
rem_edge_grid!(g, s, d) = error("Can't remove edges to immutable graph.")
rem_edge_grid!(g, e) = rem_edge_grid!(g, edgetype(g)(e))
rem_edge_grid!(g, e::AbstractEdge) = rem_edge_grid!(g, src(e), dst(e))
inneighbors_grid(g, v) = neighbors_grid(g, v)
outneighbors_grid(g, v) = neighbors_grid(g, v)
edges_grid(g) = NamedGridEdgeIter(g)

struct NamedGridGraph{N, ishypertorus} <: AbstractNamedGraph{NTuple{N, Int}}
    grid_size::NTuple{N, Int}
end
function NamedGridGraph(grid_size::NTuple{N, Int}, ishypertorus::Bool = false) where {N}
    return NamedGridGraph{N, ishypertorus}(grid_size)
end
# Minimal interface functions
NamedGraphs.position_graph(g::NamedGridGraph) = PositionGraphView(g)
function NamedGraphs.vertex_positions(g::NamedGridGraph)
    return Dictionary(Tuple.(CartesianIndices(grid_size(g))), 1:nv(g))
end
NamedGraphs.ordered_vertices(g::NamedGridGraph) = vertices(g)
ishypertorus(g::NamedGridGraph{<:Any, istorus}) where {istorus} = istorus
grid_size(g::NamedGridGraph) = g.grid_size
grid_ndims(::Type{<:NamedGridGraph{N}}) where {N} = N
Graphs.is_directed(G::Type{<:NamedGridGraph}) = false

# Derived functions
Graphs.edgetype(G::Type{<:NamedGridGraph}) = edgetype_grid(G)
Graphs.edgetype(g::NamedGridGraph) = edgetype_grid(g)
Graphs.nv(g::NamedGridGraph) = nv_grid(g)
Graphs.ne(g::NamedGridGraph) = ne_grid(g)
Graphs.vertices(g::NamedGridGraph) = vertices_grid(g)
Graphs.has_vertex(g::NamedGridGraph, v) = has_vertex_grid(g, v)
Graphs.add_vertex!(g::NamedGridGraph, v) = add_vertex_grid!(g, v)
Graphs.rem_vertex!(g::NamedGridGraph, v) = rem_vertex_grid!(g, v)
Graphs.has_edge(g::NamedGridGraph, s, d) = has_edge_grid(g, s, d)
Graphs.has_edge(g::NamedGridGraph, e) = has_edge_grid(g, e)
Graphs.has_edge(g::NamedGridGraph, e::AbstractNamedEdge) = has_edge_grid(g, e)
Graphs.add_edge!(g::NamedGridGraph, s, d) = add_edge_grid!(g, s, d)
Graphs.add_edge!(g::NamedGridGraph, e) = add_edge_grid!(g, e)
Graphs.add_edge!(g::NamedGridGraph, e::AbstractNamedEdge) = add_edge_grid!(g, e)
Graphs.rem_edge!(g::NamedGridGraph, s, d) = rem_edge_grid!(g, s, d)
Graphs.rem_edge!(g::NamedGridGraph, e) = rem_edge_grid!(g, e)
Graphs.rem_edge!(g::NamedGridGraph, e::AbstractNamedEdge) = rem_edge_grid!(g, e)
Graphs.neighbors(g::NamedGridGraph, v) = neighbors_grid(g, v)
Graphs.inneighbors(g::NamedGridGraph, v) = inneighbors_grid(g, v)
Graphs.outneighbors(g::NamedGridGraph, v) = outneighbors_grid(g, v)
Graphs.edges(g::NamedGridGraph) = edges_grid(g)
