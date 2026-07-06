module GraphGenerators
using Dictionaries: Dictionary
using Graphs.SimpleGraphs: SimpleDiGraph, SimpleGraph, binary_tree
using Graphs: add_edge!, dst, edges, nv, src

function comb_tree(dims::Tuple)
    @assert length(dims) == 2
    nx, ny = dims
    return comb_tree(fill(ny, nx))
end

function comb_tree(tooth_lengths::Vector{<:Integer})
    @assert all(>(0), tooth_lengths)
    nv = sum(tooth_lengths)
    nx = length(tooth_lengths)
    ny = maximum(tooth_lengths)
    vertex_coordinates = filter(Tuple.(CartesianIndices((nx, ny)))) do (jx, jy)
        return jy <= tooth_lengths[jx]
    end
    coordinate_to_vertex = Dictionary(vertex_coordinates, 1:nv)
    graph = SimpleGraph(nv)
    for (jx, jy) in vertex_coordinates
        if jy == 1 && jx < nx
            add_edge!(
                graph,
                coordinate_to_vertex[(jx, jy)],
                coordinate_to_vertex[(jx + 1, jy)]
            )
        end
        if jy < tooth_lengths[jx]
            add_edge!(
                graph,
                coordinate_to_vertex[(jx, jy)],
                coordinate_to_vertex[(jx, jy + 1)]
            )
        end
    end
    return graph
end

# TODO: More efficient implementation based
# on the implementation of `binary_tree`.
function binary_arborescence(k::Integer)
    graph = binary_tree(k)
    digraph = SimpleDiGraph(nv(graph))
    for e in edges(graph)
        @assert dst(e) > src(e)
        add_edge!(digraph, e)
    end
    return digraph
end
end
