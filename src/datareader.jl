# return info comment strings for UF sparse matrix
if VERSION >= v"0.7.0-"
    Sparse = SuiteSparse.CHOLMOD.Sparse
elseif isdefined(:SparseArrays)
    Sparse = Base.SparseArrays.CHOLMOD.Sparse
else
    Sparse = Base.SparseMatrix.CHOLMOD.Sparse
end

function ufinfo(filename::AbstractString)
    io = IOBuffer()
    open(filename,"r") do mmfile
        ll = readline(mmfile)
        while length(ll) > 0 && ll[1] == '%'
            println(io, ll)
            ll = readline(mmfile)
        end
    end
    String(take!(io))
end

function ufinfo(filename::AbstractString, name::AbstractString)
    strt = "% " * name * ":"
    open(filename,"r") do mmfile
        ll = readline(mmfile)
        while length(ll) > 0 && ll[1] == '%'
            if startswith(ll, strt)
                return strip(ll[length(strt)+1:end])
            end
            ll = readline(mmfile)
        end
        ""
    end
end

# read Matrix Market data
"""
`mmreader(dir, name, info)`

dir: directory of the file
name: file name
info: whether to return infomation
"""
function mmreader(dir::AbstractString, name::AbstractString; info::Bool = true)
    pathfilename = string(dir, '/', name, ".mtx")
    if info
        println(ufinfo(pathfilename))
        println("use matrixdepot(\"$name\", :read) to read the data")
    else
        sparse(Sparse(pathfilename))
    end
end

# read UF sparse matrix data
"""
`ufreader(dir, name, info, meta)`

dir: directory of the file
name: file name
info: whether to return information
meta: whether to return metadata
"""
function ufreader(dir::AbstractString, name::AbstractString;
                  info::Bool = true, meta::Bool = false)
    dirname = string(dir, '/', name)
    files = filenames(dirname)
    if info
        println(ufinfo(string(dirname, '/', name, ".mtx")))
        if length(files) > 1
            println("metadata:")
            display(files)
        end
        #println("use matrixdepot(\"$name\", :read) to read the data")
    else
        A = sparse(Sparse(string(dirname, '/', name, ".mtx")))
        if meta
            metadict = Dict{AbstractString, Any}()
            datafiles = readdir(dirname)
            for data in datafiles
                dataname = split(data, '.')[1]
                if endswith(data, "mtx")
                    try
                        metadict[dataname] =  sparse(Sparse(string(dirname, '/', data)))
                    catch
                        metadict[dataname] = denseread(string(dirname,'/', data))
                    end
                else
                    metadict[dataname] = read(string(dirname,'/', data), String)
                end
            end
            metadict
        else
            A
        end        
    end
end
