using IonicEfus
using IonicEfus.Tokens

@testset "Tokenizer" begin
    @testset "Basic Tokenization" begin
        # Test simple component call
        code = "Button text=\"Hello\""
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        @test length(tokens) >= 4  # IDENTIFIER, IDENTIFIER, EQUAL, STRING, EOF
        @test tokens[1].type == Tokens.IDENTIFIER
        @test tokens[1].token == "Button"
        @test tokens[2].type == Tokens.IDENTIFIER
        @test tokens[2].token == "text"
        @test tokens[3].type == Tokens.EQUAL
        @test tokens[4].type == Tokens.STRING
        @test tokens[4].token == "\"Hello\""
    end

    @testset "Indentation Handling" begin
        code = """
        Parent
          Child text="hello"
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        # Should have INDENT and DEDENT tokens
        indent_tokens = filter(t -> t.type == Tokens.INDENT, tokens)
        dedent_tokens = filter(t -> t.type == Tokens.DEDENT, tokens)
        @test length(indent_tokens) == 1
        @test length(dedent_tokens) == 1
    end

    @testset "Snippet Definition" begin
        code = "label(text::String, size::Int = 12)"
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        @test tokens[1].type === Tokens.IDENTIFIER
        @test tokens[2].type === Tokens.JULIAEXPR
    end

    @testset "Julia Expressions" begin
        code = "Component value=(x + y * 2)"
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        julia_tokens = filter(t -> t.type == Tokens.JULIAEXPR, tokens)
        @test length(julia_tokens) == 1
        @test julia_tokens[1].token == "(x + y * 2)"
    end

    @testset "Control Flow" begin
        code = """
        for item in items
          Component data=item
        end
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        @test any(t -> t.type == Tokens.FOR, tokens)
        @test any(t -> t.type == Tokens.IN, tokens)
        @test any(t -> t.type == Tokens.END, tokens)
    end

    @testset "Conditional Flow" begin
        code = """
        if condition
          TrueComponent
        else
          FalseComponent
        end
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        @test any(t -> t.type == Tokens.IF, tokens)
        @test any(t -> t.type == Tokens.ELSE, tokens)
        @test any(t -> t.type == Tokens.END, tokens)
    end

    @testset "Comments" begin
        code = """
        Component text="hello"  # This is a comment
        # Full line comment
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        comment_tokens = filter(t -> t.type == Tokens.COMMENT, tokens)
        @test length(comment_tokens) == 2
    end

    @testset "Numeric and Symbol Tokens" begin
        code = "Component count=42 symbol=:mysymbol"
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        numeric_tokens = filter(t -> t.type == Tokens.NUMERIC, tokens)
        symbol_tokens = filter(t -> t.type == Tokens.SYMBOL, tokens)
        @test length(numeric_tokens) >= 1
        @test length(symbol_tokens) >= 1
    end

    @testset "Array Syntax" begin
        code = "Component items=[1, 2, 3]"
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        @test any(t -> t.type == Tokens.SQOPEN, tokens)
        @test any(t -> t.type == Tokens.SQCLOSE, tokens)
        @test any(t -> t.type == Tokens.COMMA, tokens)
    end

    @testset "Splat Operator" begin
        code = "Component args..."
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        splat_tokens = filter(t -> t.type == Tokens.SPLAT, tokens)
        @test length(splat_tokens) >= 1
    end

    @testset "Error Tokens" begin
        # Test unterminated string (this should produce ERROR tokens)
        code = "Component text=\"unterminated"
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        # Should complete tokenization even with errors
        @test length(tokens) > 0
        @test tokens[end].type == Tokens.EOF
    end

    @testset "Complex Nested Example" begin
        code = """
        MainContainer padding=(10, 10)
          header(title::String)
            Title text=title::WrongSyntaxButTypeAssert size=24
            if show_subtitle
              Subtitle text="Welcome" 
            end
          end
          
          for (idx, item) in enumerate(data)
            ItemCard data=item index=idx onclick=(handle_click)
          end
          
          footer
            # Status information
            StatusBar message=status'
          end
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        # Verify comprehensive token coverage
        types = Set(t.type for t in tokens)

        # Basic structure
        @test Tokens.IDENTIFIER in types
        @test Tokens.EQUAL in types
        @test Tokens.STRING in types
        @test Tokens.JULIAEXPR in types

        # Control flow
        @test Tokens.IF in types
        @test Tokens.FOR in types
        @test Tokens.IN in types
        @test Tokens.END in types

        # Indentation
        @test Tokens.INDENT in types
        @test Tokens.DEDENT in types

        # Other constructs
        @test Tokens.TYPEASSERT in types
        @test Tokens.COMMENT in types
        @test Tokens.EOF in types

        # Should have balanced indentation
        indent_count = count(t -> t.type == Tokens.INDENT, tokens)
        dedent_count = count(t -> t.type == Tokens.DEDENT, tokens)
        @test indent_count == dedent_count
    end

    @testset "Token Location Information" begin
        code = """
        Line1
          Line2
        """
        tokenizer = Tokens.Tokenizer(Tokens.TextStream(code, "test"))
        tokens = Tokens.tokenize!(tokenizer)

        # All tokens should have location information
        for token in tokens
            @test hasfield(typeof(token), :location)
            @test token.location isa Tokens.Location
        end

        # First identifier should be on line 1
        first_id = findfirst(t -> t.type == Tokens.IDENTIFIER, tokens)
        @test first_id !== nothing
        @test tokens[first_id].location.start[1] == 1  # Line 1
    end
end

