# Workaround for: https://github.com/andyferris/Dictionaries.jl/issues/98
# TODO: Move to Dictionaries.jl file in NamedGraphs.jl
copy_keys_values(d::Dictionary) = Dictionary(copy(d.indices), copy(d.values))

# Dictionaries.jl patch
# TODO: delete once fixed in Dictionaries.jl
# TODO: Move to Dictionaries.jl file in NamedGraphs.jl
convert(::Type{Dictionary{I,T}}, dict::Dictionary{I,T}) where {I,T} = dict
