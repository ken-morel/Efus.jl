using IonicEfus
using Test


@testset "IonicEfus.jl" begin
    @testset "Tokens" include("./tokens.jl")
    @testset "Tokenizer" include("./tokenizer.jl")
    @testset "Parser" include("./parser.jl")
    @testset "Code Generation" include("./codegen.jl")
    @testset "Reactivity" include("./reactivity.jl")
    @testset "Integration" include("./integration.jl")
    @testset "Ast" include("./ast.jl")
end
