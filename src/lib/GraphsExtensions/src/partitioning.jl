using Graphs: AbstractGraph, AbstractSimpleGraph, nv, vertices
using SplitApplyCombine: group

"""
Graph partitioning backend
"""
struct Backend{T} end

Backend(s::Symbol) = Backend{s}()
Backend(s::String) = Backend(Symbol(s))
Backend(backend::Backend) = backend

macro Backend_str(s)
    return :(Backend{$(Expr(:quote, Symbol(s)))})
end

"""
Current default graph partitioning backend
"""
const CURRENT_PARTITIONING_BACKEND = Ref{Union{Missing, Backend}}(missing)

"""
Get the graph partitioning backend
"""
current_partitioning_backend() = CURRENT_PARTITIONING_BACKEND[]

"""
Set the graph partitioning backend
"""
function set_partitioning_backend!(backend::Union{Missing, Backend, String})
    CURRENT_PARTITIONING_BACKEND[] = Backend(backend)
    return nothing
end

function _npartitions(
        g::AbstractGraph, npartitions::Integer, nvertices_per_partition::Nothing
    )
    return npartitions
end

function _npartitions(
        g::AbstractGraph, npartitions::Nothing, nvertices_per_partition::Integer
    )
    return nv(g) ÷ nvertices_per_partition
end

function _npartitions(g::AbstractGraph, npartitions::Int, nvertices_per_partition::Int)
    return error("Can't specify both `npartitions` and `nvertices_per_partition`")
end

function _npartitions(
        g::AbstractGraph, npartitions::Nothing, nvertices_per_partition::Nothing
    )
    return error("Must specify either `npartitions` or `nvertices_per_partition`")
end

function partitions(
        g::AbstractSimpleGraph;
        npartitions = nothing,
        nvertices_per_partition = nothing,
        backend = current_partitioning_backend(),
        kwargs...,
    )
    # Metis cannot handle the edge case npartitions = 1, so we will fix it here for now.
    # TODO: Check if this is still needed, or move to `NamedGraphsMetisExt`.
    if (_npartitions(g, npartitions, nvertices_per_partition) == 1)
        return group(v -> 1, collect(vertices(g)))
    end
    return partitions(
        Backend(backend), g, _npartitions(g, npartitions, nvertices_per_partition); kwargs...
    )
end

# partitionings(g::AbstractGraph) = [vertices(g)]
