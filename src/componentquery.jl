@kwdef struct ComponentSearchSpec
  maxdepth::Union{UInt,Nothing} = nothing
  limit::Union{UInt,Nothing} = nothing
  name::Union{Symbol,Nothing} = nothing
  alias::Union{Symbol,Nothing} = nothing
end

function matchesspec(comp::AbstractComponent, spec::ComponentSearchSpec)::Bool
  if !isnothing(spec.name) && templatename(comp) != spec.name
    return false
  end
  if !isnothing(spec.alias) && !hasalias(comp, spec.alias)
    return false
  end
  return true
end

function query(
  comp::AbstractComponent;
  specs...,
)
  query(comp, ComponentSearchSpec(; specs...))
end

function query(
  comp::AbstractComponent,
  spec::ComponentSearchSpec
)::Channel{AbstractComponent}
  Channel{AbstractComponent}() do channel
    queue = Tuple{AbstractComponent,UInt}[(c, 1) for c in getchildren(comp)]
    items_found = zero(UInt)
    while !isempty(queue)
      current_comp, current_depth = popfirst!(queue)

      if !isnothing(spec.maxdepth) && current_depth > spec.maxdepth
        continue
      end

      if matchesspec(current_comp, spec)
        put!(channel, current_comp)
        items_found += 1
        if !isnothing(spec.limit) && items_found >= spec.limit
          return
        end
      end

      if isnothing(spec.maxdepth) || current_depth < spec.maxdepth
        for child_node in getchildren(current_comp)
          push!(queue, (child_node, current_depth + 1))
        end
      end
    end
  end
end

function queryone( # Gemini adviced me to list parameters
  comp::AbstractComponent;
  maxdepth::Union{UInt,Nothing}=nothing,
  name::Union{Symbol,Nothing}=nothing,
  alias::Union{Symbol,Nothing}=nothing
)::Union{AbstractComponent,Nothing}
  spec_for_one = ComponentSearchSpec(
    maxdepth=maxdepth,
    name=name,
    alias=alias,
    limit=UInt(1)
  )
  ch = query(comp, spec_for_one)
  for item in ch
    return item
  end
  return nothing
end
