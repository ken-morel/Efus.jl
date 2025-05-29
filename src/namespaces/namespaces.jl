export DictNamespace, gettemplate, getmodule, addtemplate!, importmodule!

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
  names::AbstractNamespace, observer::AbstractObserver, fn::Function, vars::Vector{Symbol},
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
function getreactant(namespace::DictNamespace, name::Symbol)
  #TODO
end
