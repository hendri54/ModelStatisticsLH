Pkg.activate("./docs");

using Documenter, FilesLH

makedocs(
    modules = [ModelStatisticsLH],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "hendri54",
    sitename = "ModelStatisticsLH",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

pkgDir = rstrip(normpath(@__DIR__, ".."), '/');
@assert endswith(pkgDir, "ModelStatisticsLH")
deploy_docs(pkgDir);

Pkg.activate(".");

# -------------