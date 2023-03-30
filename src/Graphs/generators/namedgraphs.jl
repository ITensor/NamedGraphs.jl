"""Generate a graph which corresponds to a hexagonal tiling of the plane. There are m rows and n columns of hexagons.
Based off of the generator in Networkx hexagonal_lattice_graph()"""
function hexagonal_lattice_graph(m::Int64, n::Int64; periodic = false)

    M = 2 * m 
    rows = [i for i in 1:M+2]
    cols = [i for i in 1:n+1]
  
    G = NamedGraph([(i, j) for i in cols for j in rows])
  
    col_edges = [(i, j) => (i, j + 1) for i in cols for j in rows[1:(M+1)]]exit
    row_edges = [(i, j) => (i+1, j) for i in cols[1:n] for j in rows if i % 2 == j % 2]
    add_edges!(G, col_edges)
    add_edges!(G, row_edges)
    rem_vertex!(G, (1, M+2))
    rem_vertex!(G, (n+1, (M+1)*(n%2) + 1))

    if periodic
        for i in cols[1:n]
            #Contract (i+1, M+1) onto (i+1, 1)
        end
        
        for i in cols[2:]
            #Contract (i+1, M+2) onto (i+1, 2)
        end

        for j in rows[2:M]
            #Contract (1, j+1) onto (n+1, j+1)
        end

        rem_vertex!(G, (n+1, M+1))

    end
  
    return G
  
  end