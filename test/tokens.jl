@testset "Locations" begin
    locs = [Tokens.loc(1, 1), Tokens.loc(5, 5)]
    locations = [Tokens.Location((1, 1), (1, 1), "hello"), Tokens.Location((5, 5), (5, 5), "world")]
    @test_throws MethodError locs[1] * locs[2]
    @test let pos = locs[1] * locations[2]
        pos.start == locs[1] &&
            pos.stop == locations[2].stop &&
            pos.file == locations[2].file
    end
    @test let pos = locations[1] * locs[2]
        pos.start == locations[1].start &&
            pos.stop == locs[2] &&
            pos.file == locations[1].file
    end
    @test_throws AssertionError locations[1] * locations[2]
    @test  locations[1] * locs[2] == locations[1] * (locations[1] * locs[2])
end
@testset "TextStream" begin
    @testset "Integrity&&Coherence" begin
        textstreams = [
            Tokens.TextStream("Hello world!", "test"),
            Tokens.TextStream(
                Channel{Char}() do channel
                    for c in "Hello world!"
                        put!(channel, c)
                    end
                end,
                "test"
            ),
            Tokens.TextStream(IOBuffer("Hello world!"), "test"),
        ]
        for stream in textstreams
            @test Tokens.peek(stream) == 'H' && Tokens.test(stream, ==('H'))
            @test Tokens.next!(stream) == 'e'
            @test Tokens.take_while!(∈("le"), stream) == ("ell", Tokens.Location((1, 2), (1, 4), "test"))
            @test Tokens.peek(stream) == ('o')
        end

    end
    @testset "Stacking" begin
        identifier = "alove!mπy"
        spaces = "    "
        ts = Tokens.TextStream("$identifier.$spaces")
        @test Tokens.stack_while!(ts, Meta.isidentifier)[1] == identifier
        Tokens.next!(ts)
        @test Tokens.take_while!(ts, isspace)[1] == spaces
    end
    @testset "Boundaries" begin
        ts = Tokens.TextStream("Hello\nWorld")
        @test Tokens.bol(ts) && !Tokens.eol(ts) && !Tokens.eof(ts)
        Tokens.skip_while!(ts, isletter)
        @test !Tokens.bol(ts) && Tokens.eol(ts) && !Tokens.eof(ts)
        Tokens.next!(ts)
        @test Tokens.bol(ts) && !Tokens.eol(ts) && !Tokens.eof(ts)
        Tokens.take_while!(ts, isletter)
        @test !Tokens.bol(ts) && Tokens.eol(ts) && Tokens.eof(ts)
        @test isnothing(Tokens.next!(ts))
    end
end
