module QuantumOperatorAlgebra

export Op, LocalOp

using LightSumTypes
using VectorInterface
import VectorInterface: scalartype
using TermInterface
using Dictionaries

import Base: +, *, -, /, \
import Base: one, zero, isone, iszero
import Base: show, show_unquoted

include("symbolicalgebra/abstractalgebra.jl")
include("symbolicalgebra/localalgebra.jl")

end
