--- crossref-register-prepare – prepare metadata for DOI registration in Crossref.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref-register-prepare.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Add fields necessary for DOI registration in Crossref:
--                    (a) Generate 'unix_epoch' (unix epoch time).
--                    (b) Generate 'journal.abbrev-title-doibatch' (abbreviated journal title
--                       with spaces replaced by '_').
--                    (c) Modify 'abstract' and 'metadata_lang[i].abstract' to return a
--                       'MetaString' (not enclosed in <p>).
--                    (d) Standarize language code (remove regional code).
--				[es] Agrega campos necesarios para el registro de DOI en Crossref:
--                    (a) Genera 'unix_epoch' (tiempo unix epoch).
--                    (b) Genera 'journal.abbrev-title-doibatch' (título de la revista abreviado 
--                       con espacios reemplazados por '_').
--                    (c) Modifica 'abstract' y 'metadata_lang[i].abstract' para devolver un 
--                       'MetaString' (no encerrado en <p>).
--                    (d) Estandariza el código de idioma (saca código regional).
-- Return: [en] Modified metadata. Add 'doi_register.unix_epoch', 'journal.abbrev-title-doibatch',
--                modify 'abstract' and 'metadata_lang[i].abstract' to return a 'MetaString' and
--                standarize language code.
--		   [es] Meta modificado. Se agrega 'doi_register.unix_epoch', 'journal.abbrev-title-doibatch' 
--                se modifica 'abstract' y 'metadata_lang[i].abstract' para devolver un 'MetaString'
--                y se estandariza el código de idioma.

local MetaString = pandoc.MetaString
local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower

function Meta(meta)

    if not meta.doi_register then
        error('ERROR: `doi_register` is not present in metadata. ' .. 
               'Cannot proceed with DOI registration.\n')
    end

    -- (a) Generate 'unix_epoch'
    meta.doi_register.unix_epoch =  os.time()

    -- (b) Generate 'journal.abbrev-title-doibatch'
    local abrev_tit
    abrev_tit = stringify(meta.journal["abbrev-title"])
    abrev_tit = abrev_tit:gsub("%s", "_")
    
    meta.journal["abbrev-title-doibatch"] = abrev_tit

    -- (c) Modify 'abstract' and 'metadata_lang[i].abstract' to MetaString type
    if meta.abstract then
        meta.abstract = MetaString(stringify(meta.abstract))
    end

    if meta.metadata_lang then
        for i = 1, #meta.metadata_lang do
            meta.metadata_lang[i].abstract = MetaString(stringify(meta.metadata_lang[i].abstract))
        end
    end

    -- (d) Standarize language code
    meta.lang = lower(stringify(meta.lang)):match('^[a-z][a-z][a-z]*')

    return meta

end