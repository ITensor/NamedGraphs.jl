struct SubSuperVertex{V, SV}
    vertex::SuperVertex{V}
    subvertex::SV
end

Base.getindex(sv::SuperVertex, v) = SubSuperVertex(sv, v)
