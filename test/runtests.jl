using IonicEfus
using IonicEfus.Tokens
using Test


@testset "IonicEfus.jl" begin
    @testset "Tokens" begin
        include("./tokens.jl")
    end

end
