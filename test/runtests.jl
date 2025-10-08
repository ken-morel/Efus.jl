using IonicEfus
using IonicEfus.Tokens
using Test


@testset "IonicEfus.jl" begin
    @testset "Tokens" include("./tokens.jl")
    @testset "Ast" include("./ast.jl")
end
