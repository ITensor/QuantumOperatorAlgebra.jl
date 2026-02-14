using Aqua: Aqua
using QuantumOperatorAlgebra: QuantumOperatorAlgebra
using Test: @testset

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(QuantumOperatorAlgebra)
end
