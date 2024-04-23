--- continuous-publication.lua – Modifies date element if continuous publication 
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/continuous-publication.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

function Meta(meta)

    if not meta.date then
        local history = meta.history
        if history then
            for i = 1, #history do
                print(history[i].type)
                if pandoc.utils.strngify(history[i].type) == "epub" then
                    meta.date = {}
                    date.year = history[i].year
                    date.month = history[i].month
                    date.day = history[i].day
                end
            end
        end

        if not meta.date then
            error('You must provide a "date" field (in _issue.yaml) or, alternatively,' .. 
                    ' a "type: epub" element within a table in the "history" field (in article.yaml).')
        end
         
    end
end
