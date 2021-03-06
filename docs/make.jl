using Documenter, DiffOpt

makedocs(;
    modules=[DiffOpt],
    doctest = false,
    clean = true,
    format=Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        mathengine = Documenter.MathJax(),
    ),
    pages=[
        "Home" => "index.md",
        "Introduction" => "intro.md",
        "Manual" => "manual.md",
        "Usage" => "usage.md",
        "Reference" => "reference.md",
        "Examples" => [
            "Solving an LP" => "solve-LP.md",
            "Solving a QP" => "solve-QP.md",
            "Solving conic with PSD and SOC constraints" => "solve-conic-1.md",
            "Differentiating a simple QP by hand" => "matrix-inversion-manual.md",
            "Sensitivity Analysis SVM" => "sensitivity-analysis-svm.md",
            "ChainRules integration" => "chainrules_unit.md",
        ],
    ],
    strict = true,  # See https://github.com/JuliaOpt/JuMP.jl/issues/1576
    repo="https://github.com/jump-dev/DiffOpt.jl",
    sitename="DiffOpt.jl",
    authors="JuMP Community",
)

deploydocs(
    repo   = "github.com/jump-dev/DiffOpt.jl.git",
    push_preview = true,
)
