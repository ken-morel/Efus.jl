using IonicEfus
using IonicEfus.Parser
using IonicEfus.Ast

@testset "Parser" begin
    @testset "Basic Component Parsing" begin
        code = "Button text=\"Hello\" size=12"
        block = parse_efus(code, "test")::Ast.Block
        ast = block.children::Vector{Ast.Statement}

        @test length(ast) == 1
        @test ast[1] isa Ast.ComponentCall
        @test ast[1].componentname == :Button
    end

    @testset "Component Arguments" begin
        code = "Button text=\"Hello\" size=12 active=true"
        block = parse_efus(code, "test")::Ast.Block
        component = block.children[1]::Ast.ComponentCall

        @test length(component.arguments) >= 3
        # Arguments are tuples: (name::Symbol, splat::Union{Nothing, Symbol}, value::Expression)
        arg_names = [arg[1] for arg in component.arguments]  # First element is the name
        @test :text in arg_names
        @test :size in arg_names
        @test :active in arg_names
    end

    @testset "Simple Snippet Parsing" begin
        code = """
        label(text::String)
          Label text=text
        end
        """
        snippets = parse_efus(code, "test").snippets

        @test length(snippets) == 1
        @test snippets[1].name == :label
        @test length(snippets[1].params) == 1
        @test snippets[1].params[1].name == :text
    end

    @testset "Snippet with Default Parameters" begin
        code = """
        button(text::String, size::Int = 16, enabled::Bool = true)
          Button text=text font_size=size disabled=(!enabled)
        end
        """
        snippets = parse_efus(code, "test").snippets

        @test length(snippets) == 1
        snippet = snippets[1]
        @test snippet.name == :button
        @test length(snippet.params) == 3

        # Check parameter details
        params = snippet.params
        @test params[1].name == :text
        @test params[2].name == :size
        @test params[3].name == :enabled

        # Check default values exist for size and enabled
        @test params[2].default !== nothing
        @test params[3].default !== nothing
    end

    @testset "Nested Components" begin
        code = """
        Container
          Header title=\"Welcome\"
          Content
            Button text=\"Click me\"
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        container = ast[1]
        @test container isa Ast.ComponentCall
        @test container.componentname == :Container
        @test length(container.children) == 2  # Header and Content

        header = container.children[1]
        @test header isa Ast.ComponentCall
        @test header.componentname == :Header

        content = container.children[2]
        @test content isa Ast.ComponentCall
        @test content.componentname == :Content
        @test length(content.children) == 1  # Button inside Content

        button = content.children[1]
        @test button isa Ast.ComponentCall
        @test button.componentname == :Button
    end

    @testset "For Loop Parsing" begin
        code = """
        for item in items
          Item data=item
        end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        for_loop = ast[1]::Ast.For
        # For has: iterator, iterating, block fields (not var, children)
        @test for_loop.iterator isa Ast.Julia
        @test for_loop.iterating isa Ast.Julia
        @test length(for_loop.block.children) == 1
        @test for_loop.block.children[1] isa Ast.ComponentCall
    end

    @testset "Nested For Loops" begin
        code = """
        for row in rows
          for col in columns
            Cell row=row col=col
          end
        end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        outer_loop = ast[1]::Ast.For

        inner_loop = outer_loop.block.children[1]::Ast.For
        @test inner_loop isa Ast.For
    end

    @testset "If Statement Parsing" begin
        code = """
        if condition
          TrueComponent
        end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        if_stmt = ast[1]::Ast.If
        @test length(if_stmt.branches) >= 1
        @test if_stmt.branches[1].condition !== nothing
        @test length(if_stmt.branches[1].block.children) == 1
        @test if_stmt.branches[1].block.children[1] isa Ast.ComponentCall
    end

    @testset "If-Else Statement Parsing" begin
        code = """
        if show_content
          MainContent
        else
          PlaceholderContent
        end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        if_stmt = ast[1]::Ast.If

        # Should have both if and else branches
        @test length(if_stmt.branches) == 2
        @test if_stmt.branches[1].condition !== nothing  # if branch
        @test if_stmt.branches[2].condition === nothing  # else branch
    end

    @testset "If-ElseIf-Else Chain" begin
        code = """
        if condition1
          Component1
        elseif condition2
          Component2
        elseif condition3
          Component3
        else
          DefaultComponent
        end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        if_stmt = ast[1]
        @test if_stmt isa Ast.If

        # Should handle multiple elseif branches
        @test length(if_stmt.branches) >= 3
    end

    @testset "Julia Block Parsing" begin
        code = """
        Component
          (begin
            x = calculate_value()
          end)
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        component = ast[1]
        @test component isa Ast.ComponentCall
        @test length(component.children) == 1
        @test component.children[1] isa Ast.JuliaBlock
    end

    @testset "Complex Julia Expressions" begin
        code = """
        Component value=(
          complex_calculation(data, params);
          ) items=([process(x) for x in raw_data])
          callback(x)
            (begin
              handle_event(x, state);
            end)
          end
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        component = ast[1]
        @test component isa Ast.ComponentCall
        @test length(component.arguments) == 2
        @test length(component.snippets) == 1
    end

    @testset "Reactive Expressions" begin
        code = """
        Component value=counter' message=status' computed=(
          derived_value' * escaped_quote''
        )
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        component = ast[1]
        @test component isa Ast.ComponentCall
        @test length(component.arguments) == 3
    end

    @testset "Type Assertions" begin
        code = """
        Component \
        text=(value)::String \
        count=(number)::Int \
        handler=(callback)::Function \
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        component = ast[1]
        @test component isa Ast.ComponentCall
        @test length(component.arguments) == 3
    end

    @testset "Array and Splat Syntax" begin
        code = """
        Component \
        items=[1, 2, 3] \
        props... \
        extra_args... \
        """
        ast = parse_efus(code, "test").children

        @test length(ast) == 1
        component = ast[1]
        @test component isa Ast.ComponentCall
        @test length(component.arguments) === 1
        @test length(component.splats) === 2
    end

    @testset "Comments Integration" begin
        code = """
        # Main container component
        Container padding=10  # Set padding
          # Header section
          Header title="App"
          
          # Content with conditional display
          if user_logged_in  # Check login status
            UserDashboard  # Show dashboard
          else
            LoginForm  # Show login
          end
          
          # Footer always visible
          Footer  # Simple footer
        """
        ast = parse_efus(code, "test").children

        # Should parse successfully despite comments
        @test length(ast) == 1
        container = ast[1]
        @test container isa Ast.ComponentCall
        @test container.componentname == :Container
        @test length(container.children) == 3  # Header, If statement, Footer
    end

    @testset "Mixed Constructs Integration" begin
        code = """
        header_section(title::String, user::User)
          AppHeader  \
        title=title
            if user.is_admin
              AdminPanel
            end
        end
        AppContainer
          main_content
            for (section_id, section) in sections
              Section  \
        id=section_id \
        title=(section.title) \
        
                for item in section.items
                  if item.visible
                    Item data=item onclick=(handle_item_click(item.id))
                  end
                end
                
                (begin
                  # Custom processing
                  process_section(section)
                end)
            end
          
          footer_area
            Footer copyright="2024"
        """

        block = parse_efus(code, "test")
        ast = block.children
        snippets = block.snippets

        # Should have main container
        @test length(ast) == 1
        app_container = ast[1]
        @test app_container isa Ast.ComponentCall
        @test app_container.componentname == :AppContainer

        # Should have header snippet
        @test length(snippets) == 1
        header_snippet = snippets[1]
        @test header_snippet.name == :header_section
        @test length(header_snippet.params) == 2

        # Should have complex nested structure
        @test length(app_container.children) == 2

        main_content = app_container.children[1]
        @test main_content isa Ast.ComponentCall
        @test main_content.componentname == :main_content
    end

    @testset "Error Handling" begin
        # Test that parser handles errors gracefully
        code = """
        Container
          Button text="hello"
        # Incomplete structure but should not crash
        """

        try
            ast = parse_efus(code, "test")
            @test true  # Parser completes without crashing
        catch e
            @test e isa Parser.ParseError  # Or produces proper error
        end
    end

    @testset "Empty and Edge Cases" begin
        # Empty input
        empty_block = parse_efus("", "test")
        @test length(empty_block.children) == 0
        @test length(empty_block.snippets) == 0

        # Only comments
        comment_only = parse_efus("# Just a comment", "test")
        @test length(comment_only.children) == 0

        # Single component
        single = parse_efus("Button", "test")
        @test length(single.children) == 1
        @test single.children[1] isa Ast.ComponentCall
    end
end
