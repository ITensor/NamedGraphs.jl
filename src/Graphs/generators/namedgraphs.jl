"""Generate a graph which corresponds to a hexagonal tiling of the plane. There are m rows and n columns of hexagons.
Based off of the generator in Networkx hexagonal_lattice_graph()"""
function hexagonal_lattice_graph(m::Int64, n::Int64; periodic=false)
  M = 2 * m
  rows = [i for i in 1:(M + 2)]
  cols = [i for i in 1:(n + 1)]

  if periodic && (n % 2 == 1 || m < 2 || n < 2)
    error("Periodic Hexagonal Lattice needs m > 1, n > 1 and n even")
  end

  G = NamedGraph([(i, j) for i in cols for j in rows])

  col_edges = [(i, j) => (i, j + 1) for i in cols for j in rows[1:(M + 1)]]
  row_edges = [(i, j) => (i + 1, j) for i in cols[1:n] for j in rows if i % 2 == j % 2]
  add_edges!(G, col_edges)
  add_edges!(G, row_edges)
  rem_vertex!(G, (1, M + 2))
  rem_vertex!(G, (n + 1, (M + 1) * (n % 2) + 1))

  if periodic == true
    for i in cols[1:n]
      G = merge_vertices(G, [(i, 1), (i, M + 1)])
    end

    for i in cols[2:(n + 1)]
      G = merge_vertices(G, [(i, 2), (i, M + 2)])
    end

    for j in rows[2:M]
      G = merge_vertices(G, [(1, j), (n + 1, j)])
    end

    rem_vertex!(G, (n + 1, M + 1))
  end

  return G
end
