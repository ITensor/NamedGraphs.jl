using ..OrdinalIndexing: OrdinalSuffixedInteger, cardinal, th

Base.@propagate_inbounds function Base.getindex(
  indices::OrderedIndices, ordinal_index::OrdinalSuffixedInteger
)
  return ordered_indices(indices)[cardinal(ordinal_index)]
end
Base.@propagate_inbounds function Base.setindex!(
  indices::OrderedIndices, value, ordinal_index::OrdinalSuffixedInteger
)
  old_value = indices[ordinal_index]
  ordered_indices(indices)[cardinal(index)] = value
  delete!(index_ordinals(indices), old_value)
  set!(index_ordinals(indices), value, cardinal(index))
  return indices
end
each_ordinal_index(indices::OrderedIndices) = (Base.OneTo(length(indices))) * th

Base.@propagate_inbounds function Base.getindex(
  dict::OrderedDictionary, ordinal_index::OrdinalSuffixedInteger
)
  return dict[ordered_indices(dict)[cardinal(ordinal_index)]]
end
Base.@propagate_inbounds function Base.setindex!(
  dict::OrderedDictionary, value, ordinal_index::OrdinalSuffixedInteger
)
  index = keys(dict)[ordinal_index]
  old_value = dict[index]
  dict[index] = value
  return dict
end
each_ordinal_index(dict::OrderedDictionary) = (Base.OneTo(length(dict))) * th
