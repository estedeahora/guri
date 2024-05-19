--- continuous-publication.lua – Modifies date element if continuous publication 
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/continuous-publication.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The continuous-publication.lua is a Pandoc Lua filter that modifies the date element if 
-- continuous publication is detected.

-- Meta(meta) --------------------------------------------------------------------------------------
-- Description: [en] Modifies the date element if continuous publication is detected.
--				[es] Modifica el elemento date si se detecta publicación continua.
-- Return: [en] Modified meta, with the date element modified if continuous publication is detected.
--		   [es] Meta modificado, con el elemento date modificado si se detecta publicación continua.

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
