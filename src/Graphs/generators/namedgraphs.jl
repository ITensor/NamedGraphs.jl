"""Generate a graph which corresponds to a hexagonal tiling of the plane. There are m rows and n columns of hexagons.
Based off of the generator in Networkx hexagonal_lattice_graph()"""
function hexagonal_lattice_graph(m::Int64, n::Int64; periodic=false)
  M = 2 * m
  rows = [i for i in 1:(M + 2)]
  cols = [i for i in 1:(n + 1)]

  if periodic && (n % 2 == 1 || m < 2 || n < 2)
    error("Periodic Hexagonal Lattice needs m > 1, n > 1 and n even")
  end

  G = NamedGraph([(j, i) for i in cols for j in rows])

  col_edges = [(j, i) => (j + 1, i) for i in cols for j in rows[1:(M + 1)]]
  row_edges = [(j, i) => (j, i + 1) for i in cols[1:n] for j in rows if i % 2 == j % 2]
  add_edges!(G, col_edges)
  add_edges!(G, row_edges)
  rem_vertex!(G, (M + 2, 1))
  rem_vertex!(G, ((M + 1) * (n % 2) + 1, n + 1))

  if periodic == true
    for i in cols[1:n]
      G = merge_vertices(G, [(1, i), (M + 1, i)])
    end

    for i in cols[2:(n + 1)]
      G = merge_vertices(G, [(2, i), (M + 2, i)])
    end

    for j in rows[2:M]
      G = merge_vertices(G, [(j, 1), (j, n + 1)])
    end

    rem_vertex!(G, (M + 1, n + 1))
  end

  return G
end

"""Generate a graph which corresponds to a equilateral triangle tiling of the plane. There are m rows and n columns of triangles.
Based off of the generator in Networkx triangular_lattice_graph()"""
function triangular_lattice_graph(m::Int64, n::Int64; periodic=false)
  N = floor(Int64, (n + 1) / 2.0)
  rows = [i for i in 1:(m + 1)]
  cols = [i for i in 1:(N + 1)]

  if periodic && (n < 5 || m < 3)
    error("Periodic Triangular Lattice needs m > 2, n > 4")
  end

  G = NamedGraph([(j, i) for i in cols for j in rows])

  grid_edges1 = [(j, i) => (j, i + 1) for j in rows for i in cols[1:N]]
  grid_edges2 = [(j, i) => (j + 1, i) for j in rows[1:m] for i in cols]
  add_edges!(G, vcat(grid_edges1, grid_edges2))

  diagonal_edges1 = [(j, i) => (j + 1, i + 1) for j in rows[2:2:m] for i in cols[1:N]]
  diagonal_edges2 = [(j, i + 1) => (j + 1, i) for j in rows[1:2:m] for i in cols[1:N]]
  add_edges!(G, vcat(diagonal_edges1, diagonal_edges2))

  if periodic == true
    for i in cols
      G = merge_vertices(G, [(1, i), (m + 1, i)])
    end

    for j in rows[1:m]
      G = merge_vertices(G, [(j, 1), (j, N + 1)])
    end

  elseif n % 2 == 1
    rem_vertices!(G, [(j, N + 1) for j in rows[2:2:(m + 1)]])
  end

  return G
end
