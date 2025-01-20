# QuantumOperatorAlgebra.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ITensor.github.io/QuantumOperatorAlgebra.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ITensor.github.io/QuantumOperatorAlgebra.jl/dev/)
[![Build Status](https://github.com/ITensor/QuantumOperatorAlgebra.jl/actions/workflows/Tests.yml/badge.svg?branch=main)](https://github.com/ITensor/QuantumOperatorAlgebra.jl/actions/workflows/Tests.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ITensor/QuantumOperatorAlgebra.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ITensor/QuantumOperatorAlgebra.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

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
julia> Pkg.add("QuantumOperatorAlgebra")
```

## Examples

````julia
using QuantumOperatorAlgebra: Op, Prod, Scaled, Sum, coefficient, sites, terms, which_op
using Test: @test

o1 = Op("X", 1)
o2 = Op("Y", 2)

@test which_op(o1) == "X"
@test sites(o1) == (1,)

o = o1 + o2

@test o isa Sum{Op}
@test terms(o)[1] == o1
@test terms(o)[2] == o2

o *= 2

@test o isa Sum{Scaled{Int,Op}}
@test terms(o)[1] == 2 * o1
@test terms(o)[2] == 2 * o2
@test coefficient(terms(o)[1]) == 2
@test coefficient(terms(o)[2]) == 2

o3 = Op("Z", 3)

o *= o3

@test o isa Sum{Scaled{Int,Prod{Op}}}
@test terms(o)[1] == 2 * o1 * o3
@test terms(o)[2] == 2 * o2 * o3
@test coefficient(terms(o)[1]) == 2
@test coefficient(terms(o)[2]) == 2
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

