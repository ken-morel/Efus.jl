using IonicEfus

include("./htmlcomponents.jl")

showcode = true
showstars = true

page = () -> efus"""
html
  body
    p
      if showcode
        text t="Here is the code"
      else
        text t="You cannot have access to the code"
      end
      span style:color="red" style:height=26px
        if showcode && showstars
          text t="**************"
        elseif showcode
          text t=" bgcrmyBRCRMYW"
        end
"""

println(render(page()))

showstars = false


println(render(page()))
