using Graphs: AbstractGraph, AbstractSimpleGraph, nv, vertices
using SplitApplyCombine: group

# Backend tag, dispatched on by the `partition_vertices` methods that the `ext/`
# packages define, e.g. `partition_vertices(::Backend"metis", ...)`.
struct Backend{T} end

Backend(s::Symbol) = Backend{s}()
Backend(s::String) = Backend(Symbol(s))
Backend(backend::Backend) = backend

macro Backend_str(s)
    return :(Backend{$(Expr(:quote, Symbol(s)))})
end

# Process-wide default backend for `partition_vertices`, and dead in practice:
# the `ext/` packages call `set_partitioning_backend!` at module top level, which
# runs at precompile time and writes to a `Ref` in this package's image, so the
# write is not replayed when the cached extension loads. It stays `missing` even
# after `using Metis`, which is why `partition_vertices` needs an explicit
# `backend`.
const CURRENT_PARTITIONING_BACKEND = Ref{Union{Missing, Backend}}(missing)

current_partitioning_backend() = CURRENT_PARTITIONING_BACKEND[]

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

function partition_vertices(
        g::AbstractSimpleGraph;
        npartitions = nothing,
        nvertices_per_partition = nothing,
        backend = current_partitioning_backend(),
        kwargs...
    )
    # Metis cannot handle the edge case npartitions = 1, so we will fix it here for now.
    # TODO: Check if this is still needed, or move to `NamedGraphsMetisExt`.
    if (_npartitions(g, npartitions, nvertices_per_partition) == 1)
        return group(v -> 1, collect(vertices(g)))
    end
    return partition_vertices(
        Backend(backend), g, _npartitions(g, npartitions, nvertices_per_partition);
        kwargs...
    )
end
