using Documenter, IonicEfus

makedocs(;
    sitename = "IonicEfus.jl",
    modules = [IonicEfus],
    repo = Remotes.GitHub("ken-morel", "IonicEfus.jl"),
    format = Documenter.HTML(
        assets = [],
        highlights = ["yaml"],
        ansicolor = true,
    ),
    pages = [
        "index.md",
        "Reference" => "reference/index.md",
        "Examples" => [],
    ]
)
