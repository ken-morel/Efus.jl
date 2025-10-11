include("./htmlcomponents.jl")

logform = (; login::Bool, name = "", password = "") -> efus"""
form
  h2
    if login
      text t="Login form"
    else
      text t="Signup form"
    end
  span
    text t="Your name: "
    input type="text" value=name
  span
    text t="Your password: "
    input type="password" value=password
"""

page = efus"""
html
  body
    h1
      text t="A login form"
    div
      logform login=true
    h1
      text t="A signup form"
    div
      logform login=false
"""

println(render(page))
