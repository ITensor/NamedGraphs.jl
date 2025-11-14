struct SubQuotientVertex{V, SV}
    vertex::QuotientVertex{V}
    subvertex::SV
end

Base.getindex(sv::QuotientVertex, v) = SubQuotientVertex(sv, v)
