using Documenter, IonicEfus

makedocs(;
    sitename = "IonicEfus.jl",
    modules = [IonicEfus],
    repo = Remotes.GitHub("ken-morel", "IonicEfus.jl"),
    format = Documenter.HTML(
        assets = [],
        highlights = ["yaml"],
        ansicolor = true,
        edit_link = "dev",
    ),
    pages = [
        "index.md",
        "efus.md",
        "Reference" => [
            "reference/index.md",
        ],
    ],

)
