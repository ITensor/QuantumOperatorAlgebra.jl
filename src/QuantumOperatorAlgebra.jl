module QuantumOperatorAlgebra

include("LazyApply/LazyApply.jl")
# Make these available as `QuantumOperatorAlgebra.f`.
using .LazyApply: coefficient, terms

include("op.jl")
include("trotter.jl")

end
