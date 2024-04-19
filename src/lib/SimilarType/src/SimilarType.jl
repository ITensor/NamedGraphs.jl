module SimilarType
similar_type(object) = similar_type(typeof(object))
similar_type(type::Type) = type
end
