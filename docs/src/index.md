```@meta
EditURL = "../../examples/README.jl"
```

# NamedGraphs.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://itensor.github.io/NamedGraphs.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://itensor.github.io/NamedGraphs.jl/dev/)
[![Build Status](https://github.com/ITensor/NamedGraphs.jl/actions/workflows/Tests.yml/badge.svg?branch=main)](https://github.com/ITensor/NamedGraphs.jl/actions/workflows/Tests.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ITensor/NamedGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ITensor/NamedGraphs.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Support

```@raw html
<img class="display-light-only" src="assets/CCQ.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
<img class="display-dark-only" src="assets/CCQ-dark.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
```


NamedGraphs.jl is supported by the Flatiron Institute, a division of the Simons Foundation.

## Installation instructions

This package resides in the `ITensor/ITensorRegistry` local registry.
In order to install, simply add that registry through your package manager.
This step is only required once.
```julia
julia> using Pkg: Pkg

julia> Pkg.Registry.add(url="https://github.com/ITensor/ITensorRegistry")
```
or:
```julia
julia> Pkg.Registry.add(url="git@github.com:ITensor/ITensorRegistry.git")
```
if you want to use SSH credentials, which can make it so you don't have to enter your Github ursername and password when registering packages.

Then, the package can be added as usual through the package manager:

```julia
julia> Pkg.add("NamedGraphs")
```

## Examples

````@example index
using NamedGraphs: NamedGraphs
````

Examples go here.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

