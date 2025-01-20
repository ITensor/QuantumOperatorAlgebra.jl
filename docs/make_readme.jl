using Literate: Literate
using QuantumOperatorAlgebra: QuantumOperatorAlgebra

Literate.markdown(
  joinpath(pkgdir(QuantumOperatorAlgebra), "examples", "README.jl"),
  joinpath(pkgdir(QuantumOperatorAlgebra));
  flavor=Literate.CommonMarkFlavor(),
  name="README",
)
