include("src/Efus.jl")

using .Efus

# Test various expression types
test_cases = [
    # Delimited expressions (complex expressions must be in parentheses)
    "(3, 3)",
    "(x + y)",
    "([1, 2, 3])",
    "((a + b) * c)",
    "(func(a, b))",
    "(array[x + y])",
    
    # Simple expressions (no parentheses needed)
    "myvar'",  # reactive variable
    "42",      # number
    "hello",   # simple identifier
    "myvar",   # simple identifier
]

println("Testing new unified expression parser:")
println("=" ^ 50)

for (i, test_case) in enumerate(test_cases)
    println("\nTest $i: $test_case")
    try
        result = Efus.codegen_string("Label text=$test_case")
        println("✓ Success: $result")
    catch e
        println("✗ Error: $e")
    end
end

# Test reactive expressions
println("\n" * "=" ^ 50)
println("Testing reactive expressions:")

reactive_tests = [
    "(x' + y')",      # complex reactive expression in parentheses
    "(a' * b')",      # complex reactive expression in parentheses
    "(func(x', y'))", # complex reactive expression in parentheses
    "myvar'",         # simple reactive variable
]

for (i, test_case) in enumerate(reactive_tests)
    println("\nReactive Test $i: $test_case")
    try
        result = Efus.codegen_string("Label text=$test_case")
        println("✓ Success: $result")
    catch e
        println("✗ Error: $e")
    end
end