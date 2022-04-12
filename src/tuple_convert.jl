# Tuple constructor that either keeps
# it as a Tuple or turns it into a Tuple.
_tuple(t::Tuple) = t
_tuple(x) = tuple(x)
