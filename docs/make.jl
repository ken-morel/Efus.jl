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
        "The efus language" => [
            "efus/index.md",
            "efus/compcall.md",
            "efus/controlflow.md",
            "efus/snippets.md",
            "efus/values.md",
        ],
        "Guides" => [
            "guide/component.md",
            "guide/reactivity.md",
            "guide/ionic.md",
            "guide/reactors.md",
            "guide/snippets.md",
        ],
        "Reference" => [
            "reference/index.md",
        ],
        "styleguide.md",
    ],

)
