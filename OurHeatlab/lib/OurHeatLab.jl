# 数据上传
route("/", method=POST) do
    files = Genie.Requests.filespayload()
    for f in files
        JSON3.write(joinpath(FILE_PATH, f[2].name), f[2].data)
        println()
        @info "Uploading: " * f[2].name
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "upload done"
end