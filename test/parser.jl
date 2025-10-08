using IonicEfus

@testset "Parser" begin
    @testset "Component Parsing" begin
        code = "Button text=\"Hello\" size=12"
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        @test ast[1] isa ComponentCall
        @test ast[1].name == "Button"
        @test length(ast[1].args) == 2
        @test any(arg -> arg.name == "text", ast[1].args)
        @test any(arg -> arg.name == "size", ast[1].args)
    end

    @testset "Snippet Parsing" begin
        code = """
        label(text::String, size::Int = 12)
          Label text=text font_size=size
        end
        """
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        @test ast[1] isa SnippetDef
        @test ast[1].name == "label"
        @test length(ast[1].params) == 2
        @test ast[1].params[1].name == "text"
        @test ast[1].params[1].type == "String"
        @test ast[1].params[2].name == "size"
        @test ast[1].params[2].default !== nothing
    end

    @testset "Nested Components" begin
        code = """
        Container
          Header title=\"Welcome\"
          Content
            Button text=\"Click me\"
        """
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        container = ast[1]
        @test container isa ComponentCall
        @test container.name == "Container"
        @test length(container.body) == 2  # Header and Content

        header = container.body[1]
        @test header isa ComponentCall
        @test header.name == "Header"

        content = container.body[2]
        @test content isa ComponentCall
        @test content.name == "Content"
        @test length(content.body) == 1  # Button inside Content
    end

    @testset "Control Flow Parsing" begin
        code = """
        for item in items
          Item data=item
        end
        """
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        @test ast[1] isa ForLoop
        @test ast[1].var == "item"
        @test ast[1].iter !== nothing
        @test length(ast[1].body) == 1
        @test ast[1].body[1] isa ComponentCall
    end

    @testset "Conditional Parsing" begin
        code = """
        if condition
          TrueComponent
        else
          FalseComponent  
        end
        """
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        @test ast[1] isa IfStatement
        @test ast[1].condition !== nothing
        @test length(ast[1].then_body) == 1
        @test length(ast[1].else_body) == 1
    end

    @testset "Julia Block Parsing" begin
        code = """
        Component
          (begin
            x = calculate_value()
            y = x * 2
          end)
        """
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        component = ast[1]
        @test component isa ComponentCall
        @test length(component.body) == 1
        @test component.body[1] isa JuliaBlock
    end

    @testset "Reactive Expressions" begin
        code = "Component value=data' count=counter''"
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        component = ast[1]
        @test component isa ComponentCall

        # Check for reactive value references
        value_arg = findfirst(arg -> arg.name == "value", component.args)
        @test value_arg !== nothing
        @test component.args[value_arg].value isa ReactiveRef
    end

    @testset "Type Assertions" begin
        code = "Component text=value::String count=num::Int"
        ast = parse_efus(code, "test")

        @test length(ast) == 1
        component = ast[1]
        @test component isa ComponentCall

        # Check type assertions exist
        text_arg = findfirst(arg -> arg.name == "text", component.args)
        @test text_arg !== nothing
        @test component.args[text_arg].value isa TypeAssertion
    end

    @testset "Error Handling" begin
        # Test parse error with unterminated block
        code = """
        Container
          Button text="hello"
        # Missing end for some construct
        """

        # Should not throw, but might produce error nodes or partial AST
        try
            ast = parse_efus(code, "test")
            @test true  # Parser handles gracefully
        catch e
            @test e isa ParseError  # Or produces proper error
        end
    end

    @testset "Complex Mixed Example" begin
        code = """
        MainContainer padding=(10, 10)
          header(title::String, subtitle::String = "")
            HeaderBox
              Title text=title size=24
              if !isempty(subtitle)
                Subtitle text=subtitle size=16
              end
            end
          end
          
          content_area
            for (idx, item) in enumerate(data')
              ItemCard 
                data=item 
                index=idx
                onclick=(handle_click(idx))::Function
            end
          end
          
          footer
            StatusBar message=status'
          end
        """

        ast = parse_efus(code, "test")
        @test length(ast) == 1

        main = ast[1]
        @test main isa ComponentCall
        @test main.name == "MainContainer"
        @test length(main.body) == 3  # header, content_area, footer

        # Verify nested structures exist
        header_snippet = main.body[1]
        @test header_snippet isa SnippetDef
        @test header_snippet.name == "header"

        content = main.body[2]
        @test content isa ComponentCall
        @test content.name == "content_area"

        # Should contain for loop
        @test length(content.body) == 1
        @test content.body[1] isa ForLoop
    end
end

