using ..OrdinalIndexing: OrdinalSuffixedInteger, th
Base.@propagate_inbounds function Base.getindex(
  indices::OrderedIndices, i::OrdinalSuffixedInteger
)
  return indices.ordered_indices[Integer(i)]
end
Base.@propagate_inbounds function Base.setindex!(
  indices::OrderedIndices, value, index::OrdinalSuffixedInteger
)
  old_value = indices.ordered_indices[Integer(index)]
  indices.ordered_indices[Integer(index)] = value
  delete!(indices.index_ordinals, old_value)
  set!(indices.index_ordinals, value, Integer(index))
  return indices
end
each_ordinal_index(indices::OrderedIndices) = (Base.OneTo(length(indices))) * th
