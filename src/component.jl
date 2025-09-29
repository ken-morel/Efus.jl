export AbstractComponent, mount!, unmount!, remount!

abstract type AbstractComponent end
abstract type AbstractComposite <: AbstractComponent end

function mount! end
function unmount! end
function remount! end
