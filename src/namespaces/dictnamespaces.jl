struct DictNamespace <: ENamespace
    variables::Dict{Symbol, Any}
    templates::Dict{Symbol, AbstractTemplate}
    parent::Union{Nothing, AbstractNamespace}
    modules::Dict{Symbol, TemplateModule}
    reactants::Dict{Symbol, AbstractReactant}
    dirty::Vector{Symbol}
    subscriptions::Vector{
        Tuple{AbstractObserver, Function, Union{Vector{Symbol}, Nothing}},
    }
    DictNamespace(parent::Union{AbstractNamespace, Nothing} = nothing) = new(
        Dict(),
        Dict(),
        parent,
        Dict(),
        Dict(),
        Symbol[],
        Vector{Tuple{AbstractObserver, Function, Vector{Symbol}}}(),
    )
end
function addsubscription!(
        namespace::DictNamespace,
        observer::Union{EObserver, Nothing},
        fn::Function,
        names::Union{Vector{Symbol}, Nothing} = nothing,
    )
    return push!(namespace.subscriptions, (observer, fn, names))
end
function varstomodule!(mod::Module, names::DictNamespace)::Module
    for (k, v) in names.variables
        Core.eval(mod, :($k = $v))
    end
    return if names.parent !== nothing
        varstomodule!(mod, names.parent)
    else
        mod
    end
end
function withmodule(fn::Function, names::DictNamespace)
    mod = Module(Symbol("Efus.Namespace$(rand(UInt64))"), true, true)
    return fn(varstomodule!(mod, names))
end
function getname(names::DictNamespace, name::Symbol, default)
    return if name in keys(names.variables)
        names.variables[name]
    elseif names.parent !== nothing
        getname(names.parent, name, default)
    else
        default
    end
end
function Base.setindex!(names::DictNamespace, value, name::Symbol)
    return names.variables[name] = value
end
