using IonicEfus.Tokens

@testset "Tokenizer" begin
    @testset "Basic Tokenization" begin
        # Test simple component call
        code = "Button text=\"Hello\""
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        @test length(tokens) >= 4  # IDENTIFIER, IDENTIFIER, EQUAL, STRING, EOF
        @test tokens[1].type == IDENTIFIER
        @test tokens[1].content == "Button"
        @test tokens[2].type == IDENTIFIER  
        @test tokens[2].content == "text"
        @test tokens[3].type == EQUAL
        @test tokens[4].type == STRING
        @test tokens[4].content == "\"Hello\""
    end
    
    @testset "Indentation Handling" begin
        code = """
        Parent
          Child text="hello"
        """
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        # Should have INDENT and DEDENT tokens
        indent_tokens = filter(t -> t.type == INDENT, tokens)
        dedent_tokens = filter(t -> t.type == DEDENT, tokens)
        @test length(indent_tokens) == 1
        @test length(dedent_tokens) == 1
    end
    
    @testset "Snippet Definition" begin
        code = "label(text::String, size::Int = 12)"
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        @test any(t -> t.type == TYPEASSERT, tokens)
        @test any(t -> t.type == EQUAL, tokens)
        @test any(t -> t.content == "String", tokens)
        @test any(t -> t.content == "Int", tokens)
    end
    
    @testset "Julia Expressions" begin
        code = "Component value=(x + y * 2)"
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        julia_tokens = filter(t -> t.type == JULIAEXPR, tokens)
        @test length(julia_tokens) == 1
        @test julia_tokens[1].content == "(x + y * 2)"
    end
    
    @testset "Control Flow" begin
        code = """
        for item in items
          Component data=item
        end
        """
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        @test any(t -> t.type == FOR, tokens)
        @test any(t -> t.type == IN, tokens)
        @test any(t -> t.type == END, tokens)
    end
    
    @testset "Comments" begin
        code = """
        Component text="hello"  # This is a comment
        # Full line comment
        """
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        comment_tokens = filter(t -> t.type == COMMENT, tokens)
        @test length(comment_tokens) == 2
    end
    
    @testset "Error Tokens" begin
        # Test unterminated string
        code = "Component text=\"unterminated"
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        error_tokens = filter(t -> t.type == ERROR, tokens)
        @test length(error_tokens) > 0
    end
    
    @testset "Complex Efus Example" begin
        code = """
        Container padding=(10, 10)
          title(text::String)
            Label text=text size=16
          end
          
          for (idx, item) in enumerate(items)
            if item.active
              ItemComponent data=item index=idx
            end
          end
        """
        tokenizer = Tokenizer(TextStream(code, "test"))
        tokens = tokenize!(tokenizer)
        
        # Verify we get all expected token types
        types = Set(t.type for t in tokens)
        @test IDENTIFIER in types
        @test EQUAL in types  
        @test JULIAEXPR in types
        @test FOR in types
        @test IN in types
        @test IF in types
        @test END in types
        @test INDENT in types
        @test DEDENT in types
    end
end