using QuantumOperatorAlgebra: QuantumOperatorAlgebra
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
  QuantumOperatorAlgebra, :DocTestSetup, :(using QuantumOperatorAlgebra); recursive=true
)

include("make_index.jl")

makedocs(;
  modules=[QuantumOperatorAlgebra],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="QuantumOperatorAlgebra.jl",
  format=Documenter.HTML(;
    canonical="https://ITensor.github.io/QuantumOperatorAlgebra.jl",
    edit_link="main",
    assets=String[],
  ),
  pages=["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
  repo="github.com/ITensor/QuantumOperatorAlgebra.jl", devbranch="main", push_preview=true
)
