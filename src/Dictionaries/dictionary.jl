# Dictionaries.jl patch
# TODO: delete once fixed in Dictionaries.jl
# TODO: Move to Dictionaries.jl file in NamedGraphs.jl
convert(::Type{Dictionary{I,T}}, dict::Dictionary{I,T}) where {I,T} = dict
