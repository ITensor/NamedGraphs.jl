abstract type AbstractSuperVertex{V} <: Any where {V} end

#Parent, wrap, unwrap, vertex?
Base.parent(sv::AbstractSuperVertex) = not_implemented()
