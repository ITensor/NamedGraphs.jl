struct SuperVertex{V} <: AbstractSuperVertex{V}
    vertex::V
end

Base.parent(sv::SuperVertex) = getfield(sv, :vertex)
