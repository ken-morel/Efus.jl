abstract type AbstractNamespaceReactant{T} <: AbstractReactant{T} end
abstract type ENamespace <: AbstractNamespace end

function Base.getindex(names::AbstractNamespace, name::Symbol)
  getname(names, name, nothing)
end
function notify(
  names::AbstractNamespace,
  bindings::Union{Nothing,Vector{Symbol}}=nothing;
  all::Bool=false
)
  warningnames = bindings === nothing ? getdirty(names) : bindings
  for (observer, fn, vars) in getsubscriptions(names)
    if all || any(var in warningnames for var in vars)
      try
        fn()
      catch e
        @warn(
          "Namespace had an error notifying observer",
          observer, "with function",
          fn,
          ", error: ",
          e,
        )
      end
    end
  end
  empty!(names.dirty)
end
function subscribe!(
  fn::Function, names::AbstractNamespace, observer::AbstractObserver, vars::Vector{Symbol},
)
  addsubscription!(names, observer, fn, vars)
end
function unsubscribe!(
  names::AbstractNamespace,
  observer::AbstractObserver,
  fn::Function,
  vars::Union{Vector{Symbol},Nothing}=nothing,
)
  dropsubscriptions!(names, observer, fn, vars)
end
subscribe!(
  names::AbstractNamespace,
  observer::AbstractObserver,
  fn::Function,
  vars::Vector{Symbol}
) = subscribe!(
  names, observer, fn, vars,
)

function dirty!(namespace::ENamespace, name::Symbol, dirt::Bool=true)
  if dirt && name ∉ namespace.dirty
    push!(namespace.dirty, name)
  elseif !dirt && name ∈ namespace.dirty
    filter!(x -> x != name, namespace.dirty)
  end
end
