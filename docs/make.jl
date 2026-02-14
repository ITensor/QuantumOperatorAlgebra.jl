using Documenter: Documenter, DocMeta, deploydocs, makedocs
using QuantumOperatorAlgebra: QuantumOperatorAlgebra

DocMeta.setdocmeta!(
    QuantumOperatorAlgebra, :DocTestSetup, :(using QuantumOperatorAlgebra); recursive = true
)

include("make_index.jl")

makedocs(;
    modules = [QuantumOperatorAlgebra],
    authors = "ITensor developers <support@itensor.org> and contributors",
    sitename = "QuantumOperatorAlgebra.jl",
    format = Documenter.HTML(;
        canonical = "https://itensor.github.io/QuantumOperatorAlgebra.jl",
        edit_link = "main",
        assets = ["assets/favicon.ico", "assets/extras.css"]
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"]
)

deploydocs(;
    repo = "github.com/ITensor/QuantumOperatorAlgebra.jl", devbranch = "main",
    push_preview = true
)
