using Graphs: add_edge!, dst, edges, neighbors, rem_edge!, rem_vertex!, src, vertices
using Graphs.SimpleGraphs: SimpleGraph
using .GraphsExtensions: GraphsExtensions, add_edges!

function GraphsExtensions.decorate_graph_edges(
  g::AbstractNamedGraph; edge_map::Function=Returns(NamedGraph(1))
)
  g_dec = copy(g)
  es = edges(g_dec)
  for e in es
    dec = edge_map(e)
    dec = rename_vertices(v -> (v, e), dec)
    g_dec = union(g_dec, dec)
    add_edge!(g_dec, src(e) => first(vertices(dec)))
    add_edge!(g_dec, dst(e) => last(vertices(dec)))
    rem_edge!(g_dec, src(e) => dst(e))
  end
  return g_dec
end

function GraphsExtensions.decorate_graph_vertices(
  g::AbstractNamedGraph; vertex_map::Function=Returns(NamedGraph(1))
)
  g_dec = copy(g)
  vs = vertices(g_dec)
  for v in vs
    vneighbors = neighbors(g_dec, v)
    dec = vertex_map(v)
    dec = rename_vertices(vdec -> (vdec, v), dec)
    g_dec = union(g_dec, dec)
    rem_vertex!(g_dec, v)
    add_edges!(g_dec, [first(vertices(dec)) => vn for vn in vneighbors])
  end
  return g_dec
end
