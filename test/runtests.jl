using Efus
using Test


@testset "Efus.jl" begin
    @testset "Tokens" include("./tokens.jl")
    @testset "Tokenizer" include("./tokenizer.jl")
    @testset "Parser" include("./parser.jl")
    @testset "Code Generation" include("./codegen.jl")
    @testset "Ast" include("./ast.jl")
end
