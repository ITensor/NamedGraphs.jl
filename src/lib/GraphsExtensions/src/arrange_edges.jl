using Graphs: AbstractEdge, AbstractGraph, IsDirected, dst, edges, rem_edge!, src
using SimpleTraits: SimpleTraits, @traitfn, Not

# Related to `MetaGraphsNext.arrange`:
# https://github.com/JuliaGraphs/MetaGraphsNext.jl/blob/1539095ee6088aba0d5b1cb057c339ad92557889/src/metagraph.jl#L75-L80
# and `Graphs.is_ordered`:
# https://juliagraphs.org/Graphs.jl/v1.7/core_functions/core/#Graphs.is_ordered-Tuple{AbstractEdge}

function is_arranged(x, y)
    if !hasmethod(isless, typeof.((x, y)))
        return is_arranged_by_hash(x, y)
    end
    return isless(x, y)
end
function is_arranged_by_hash(x, y)
    x_hash = hash(x)
    y_hash = hash(y)
    if (x_hash == y_hash) && (x ≠ y)
        @warn "Hash collision when arranging values, ordering may not be well defined."
    end
    return isless(x_hash, y_hash)
end
# https://github.com/JuliaLang/julia/blob/v1.8.5/base/tuple.jl#L470-L482
is_arranged(::Tuple{}, ::Tuple{}) = false
is_arranged(::Tuple{}, ::Tuple) = true
is_arranged(::Tuple, ::Tuple{}) = false
function is_arranged(t1::Tuple, t2::Tuple)
    a, b = t1[1], t2[1]
    return is_arranged(a, b) || (isequal(a, b) && is_arranged(Base.tail(t1), Base.tail(t2)))
end

function is_edge_arranged(e::AbstractEdge)
    return is_arranged(src(e), dst(e))
end
@traitfn function is_edge_arranged(g::AbstractGraph::IsDirected, e::AbstractEdge)
    return true
end
@traitfn function is_edge_arranged(g::AbstractGraph::(!IsDirected), e::AbstractEdge)
    return is_edge_arranged(e)
end
function arrange_edge(e::AbstractEdge)
    return is_edge_arranged(e) ? e : reverse(e)
end
function arrange_edge(g::AbstractGraph, e::AbstractEdge)
    return is_edge_arranged(g, e) ? e : reverse(e)
end
function arranged_edges(g::AbstractGraph)
    return map(e -> arrange_edge(g, e), edges(g))
end
