export AbstractComponent

abstract type AbstractComponent end

mount!(::AbstractComponent) = error("Mounting not implemented")
unmount!(::AbstractComponent) = error("Unmounting not implemented")
remount!(::AbstractComponent) = error("Remounting not implemented")
update!(::AbstractComponent) = error("Updating not implemented")
