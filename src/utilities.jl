"""Remove a list of edges from a graph g"""
function rem_edges(g::AbstractGraph, edges)
    g_out = copy(g)
    for e in edges
        rem_edge!(g_out, e)
    end

    return g_out
end

function rem_edges!(g::AbstractGraph, edges)
    for e in edges
        rem_edge!(g, e)
    end
end

"""Add a list of edges to a graph g"""
function add_edges(g::AbstractGraph, edges)
    g_out = copy(g)
    for e in edges
        add_edge!(g_out, e)
    end

    return g_out
end

function add_edges!(g::AbstractGraph, edges)
    for e in edges
        add_edge!(g, e)
    end
end