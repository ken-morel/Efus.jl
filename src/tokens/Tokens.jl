"""
Tokenizer holds the efus code tokenizer, 
it does the first step in efus code processing,
spliting the code into tokens.
"""
module Tokens
using FunctionWrappers: FunctionWrapper

include("./macros.jl")
include("./token.jl")
include("./text_stream.jl")
include("./tokenizer.jl")
include("./is.jl")
include("./ionic.jl")
include("./string.jl")

end
