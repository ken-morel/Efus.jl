include("./src/tokens/Tokens.jl")

using .Tokens


open("./test.efus") do io
    tz = Tokens.Tokenizer(Tokens.TextStream(io)) do channel
        while true
            try
                println(take!(channel))
            catch
                break
            end
        end
    end
    @time tokenize!(tz)
end
bt = nothing

tokens = []
@eval Base slow_lock_warn::Int = 0
@eval Base @inline function lock(rl::ReentrantLock)
    trylock(rl) || (
        @noinline function slowlock(rl::ReentrantLock)
            Threads.lock_profiling() && Threads.inc_lock_conflict_count()
            c = rl.cond_wait
            lock(c.lock)
            return try
                while true
                    if (@atomicreplace rl.havelock 0x01 => 0x02).old == 0x00 # :sequentially_consistent ? # now either 0x00 or 0x02
                        # it was unlocked, so try to lock it ourself
                        _trylock(rl, current_task()) && break
                    else # it was locked, so now wait for the release to notify us
                        t = nothing
                        if slow_lock_warn >= 0
                            bt = backtrace()
                            t = Timer(slow_lock_warn) do t
                                @eval @warn(
                                    "Taking longer than $(slow_lock_warn)s to get a lock",
                                    exception = (ErrorException("Lock contention warning"), $bt)
                                )
                            end
                        end
                        wait(c)
                        t === nothing || close(t)
                    end
                end
            finally
                unlock(c.lock)
            end
        end
    )(rl)
    return
end
open("./test.efus") do io
    tz = Tokens.Tokenizer(Tokens.TextStream(io)) do channel
        while true
            try
                println(take!(channel))
            catch
                break
            end
        end
    end
    @time tokenize!(tz)
end

# println.(filter!(!isnothing, tokens))
