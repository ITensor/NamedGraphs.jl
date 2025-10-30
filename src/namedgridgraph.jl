using Graphs: Graphs, edgetype, has_vertex, neighbors, vertices

# Helper functions
oneelement_tuple(j::Int, N) = ntuple(i -> i == j ? 1 : 0, N)

# Minimal interface functions
ishypertorus(g) = error("Not implemented.")
grid_size(g) = error("Not implemented.")
grid_ndims(G::Type) = error("Not implemented")
is_directed_grid(G::Type) = false

# Derived interface functions
grid_length(g) = prod(grid_size(g))
grid_ndims(g) = length(grid_size(g))
grid_ndims(::Type{<:NamedGridGraph{N}}) where {N} = N
nv_grid(g) = grid_length(g)
vertices_grid(g) = Tuple.(CartesianIndices(grid_size(g)))
has_vertex_grid(g, v) = CartesianIndex(v) in CartesianIndices(grid_size(g))
edgetype_grid(G::Type) = NamedEdge{NTuple{grid_ndims(G), Int}}
edgetype_grid(g) = NamedEdge{NTuple{grid_ndims(g), Int}}
function ne_grid(g::NamedGridGraph)
    ne_g = grid_ndims(g) * grid_length(g)
    if !ishypertorus(g)
        ne_g -= sum(sᵢ -> div(grid_length(g), sᵢ), grid_size(g))
    end
    return ne_g
end
function plus_neighbors(g, v)
    ns = [v .+ oneelement_tuple(d, length(v)) for d in 1:grid_ndims(g)]
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
function neighbors_grid(g, v)
    return [minus_neighbors(g, v); plus_neighbors(g, v)]
end
function has_edge_grid(g, s, d)
    has_vertex(g, s) || return false
    has_vertex(g, d) || return false
    return d in neighbors(g, s)
end
inneighbors_grid(g, v) = neighbors_grid(g, v)
outneighbors_grid(g, v) = neighbors_grid(g, v)
function edges_grid(g)
    return (edgetype(g)(s, d) for s in vertices(g) for d in plus_neighbors(g, s))
end

struct NamedGridGraph{N, ishypertorus} <: AbstractNamedGraph{NTuple{N, Int}}
    grid_size::NTuple{N, Int}
end
# Minimal interface functions
ishypertorus(g::NamedGridGraph{<:Any, ishypertorus}) where {ishypertorus} = ishypertorus
grid_size(g::NamedGridGraph) = g.grid_size
grid_ndims(::Type{<:NamedGridGraph{N}}) where {N} = N

# Derived functions
Graphs.is_directed(G::Type{<:NamedGridGraph}) = false
Graphs.edgetype(G::Type{<:NamedGridGraph}) = edgetype_grid(G)
Graphs.edgetype(g::NamedGridGraph) = edgetype_grid(g)
Graphs.nv(g::NamedGridGraph) = nv_grid(g)
Graphs.ne(g::NamedGridGraph) = ne_grid(g)
Graphs.vertices(g::NamedGridGraph) = vertices_grid(g)
Graphs.has_vertex(g::NamedGridGraph, v) = has_vertex_grid(g, v)
Graphs.has_edge(g::NamedGridGraph, s, d) = has_edge_grid(g, s, d)
Graphs.neighbors(g::NamedGridGraph, v) = neighbors_grid(g, v)
Graphs.inneighbors(g::NamedGridGraph, v) = inneighbors_grid(g, v)
Graphs.outneighbors(g::NamedGridGraph, v) = outneighbors_grid(g, v)
Graphs.edges(g::NamedGridGraph) = edges_grid(g)
