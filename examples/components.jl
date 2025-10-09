using IonicEfus

abstract type HTMLComponent <: Component end

abstract type HTMLOrphelineComponent <: HTMLComponent end
abstract type HTMLCoupleComponent <: HTMLComponent end

macro _html_common()
    return quote
        parent::Union{HTMLComponent, Nothing} = nothing
        classes::Vector{AbstractString} = []
        id::Union{AbstractString, Nothing} = nothing
        style::Dict = Dict()
    end
end

Base.@kwdef struct text <: HTMLComponent
    content::AbstractString
end

Base.@kwdef struct div <: HTMLCoupleComponent
    @_html_common
    children::Vector{Component} = []
end

Base.@kwdef struct span <: HTMLCoupleComponent
    @_html_common
    children::Vector{Component} = []
end

Base.@kwdef struct html <: HTMLCoupleComponent
    lang::Union{AbstractString, Nothing} = nothing
end

Base.@kwdef struct meta <: HTMLOrphelineComponent
    charset::Union{AbstractString, Nothing} = nothing
end

Base.@kwdef struct p <: HTMLCoupleComponent
    @_html_common
end
