using IonicEfus

abstract type HTMLTag <: Component end
abstract type CoupleTag <: HTMLTag end
abstract type OrphelineTag <: HTMLTag end


# Some html components

# for inline text
Base.@kwdef struct text <: HTMLTag
    t::AbstractString
end
render(t::text) = t.t

Base.@kwdef struct div <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component} = []
end
Base.@kwdef struct form <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component} = []
end
Base.@kwdef struct button <: OrphelineTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    type::Symbol
end


Base.@kwdef struct span <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component} = []
end
Base.@kwdef struct h1 <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component}
end
Base.@kwdef struct h2 <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component}
end
Base.@kwdef struct h3 <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component}
end

Base.@kwdef struct html <: CoupleTag
    children::Vector{Component} = []
    lang::String = "en"
end
render(c::html) = "<html lang=\"$(c.lang)\">$(renderchildren(c))</html>"


Base.@kwdef struct body <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component} = []
end

Base.@kwdef struct p <: CoupleTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    children::Vector{Component}
end
Base.@kwdef struct input <: OrphelineTag
    classes::Vector{AbstractString} = []
    id::Union{AbstractString, Nothing} = nothing
    style::Dict{Symbol, Any} = Dict()
    type::String = "text"
    placeholder = ""
    value = ""
end
function render(c::input)
    return """<input type="$(c.type)" value="$(c.value)" placeholder="$(c.placeholder)" $(renderargsdefault(c))/>"""
end

tagname(::T) where {T <: HTMLTag} = nameof(T)

#### Some backend logick to actually generate html
#
function render(c::CoupleTag)
    tagname = nameof(typeof(c)) |> string
    children = renderchildren(c)
    args = " " * renderargs(c) |> rstrip
    return "<$tagname$args>$children</$tagname>"
end
function render(c::OrphelineTag)
    tagname = nameof(typeof(c)) |> string
    args = " " * renderargs(c) |> rstrip
    return "<$tagname$args />"
end
render(c::Vector{Component}) = join(render.(c))
function renderargsdefault(c::HTMLTag)
    classes = if !isempty(c.classes)
        string(" class=\"", join(c.classes, " "), "\"")
    end
    style = if !isempty(c.style)
        string(" style=\"", join(["$name: $val;" for (name, val) in c.style], " "), "\"")
    end
    id = if !isnothing(c.id)
        " id=\"$(c.id)\""
    end
    return join(something.((classes, style, id), ("",))) |> strip
end
renderargs(c::HTMLTag) = renderargsdefault(c)
renderchildren(c::HTMLTag) = render(c.children)


struct Pixels{T <: Number}
    num::T
end

Base.show(io::IO, px::Pixels) = print(io, "$(px.num)px")
const px = Pixels(1.0)
Base.:*(i::Number, px::Pixels) = Pixels(px.num * i)
