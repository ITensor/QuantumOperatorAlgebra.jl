using Literate: Literate
using QuantumOperatorAlgebra: QuantumOperatorAlgebra

Literate.markdown(
  joinpath(pkgdir(QuantumOperatorAlgebra), "examples", "README.jl"),
  joinpath(pkgdir(QuantumOperatorAlgebra), "docs", "src");
  flavor=Literate.DocumenterFlavor(),
  name="index",
)
