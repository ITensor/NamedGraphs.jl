# The type of the analogous mutable graph, for wrapper types that decorate a
# parent graph (overloaded e.g. by `QuotientView` and downstream decorators).
similar_type(object) = similar_type(typeof(object))
similar_type(type::Type) = type
