using Documenter, IonicEfus

makedocs(;
    sitename = "IonicEfus.jl",
    modules = [IonicEfus],
    repo = Remotes.GitHub("ken-morel", "IonicEfus.jl"),
    pages = [
        "index.md",
        "Reference" => "reference/index.md",
        "Examples" => [],
    ]
)
