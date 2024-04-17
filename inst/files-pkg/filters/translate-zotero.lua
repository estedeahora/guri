--- translate-zotero.lua – filter to translate elements
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-zotero.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local dict = {
    es = {chapter = 'capítulo', paragraph = 'párrafo' },
    pt = {chapter = 'capítulo', paragraph = 'parágrafo' },
    fr = {chapter = 'chapitre', paragraph = 'paragraphe' },
    it = {chapter = 'capitolo', paragraph = 'paragrafi' },
    de = {chapter = 'kapitel', paragraph = 'paragraphen' },
    zh = {chapter = '章', paragraph = '段落' }
}

local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower

local lang

-- Cite(cite) --------------------------------------------------------------------------------------
-- Description: [en] Translate citation elements (coming from zotero plug-in for word in 'fields').
--				[es] Traducir elementos de cita (provenientes de complemento de zotero para word en 'campos').
-- Return: [en] An element of type pandoc.cite with suffixes translated into Spanish.
--		   [es] Un elemento de tipo pandoc.cite con sufijos traducidos al español.

function Meta(meta)
    lang = lower(stringify(meta.lang):match('^..'))
end

function Cite(cite)

    if not lang:match('^en') and not lang:match('^la') then

        for k, citation in ipairs(cite.citations)do

            if citation.suffix ~= nil then

                if dict[lang] then
                    citation.suffix = stringify(citation.suffix):
                                        gsub("page", "p."):
                                        gsub("pages", "pp."):
                                        gsub("chapter", dict[lang].chapter):
                                        gsub("paragraph", dict[lang].paragraph)
                else
                    warn('Partially supported language ("' ..  lang .. '"). No translation for citation suffix label.\n')
                end

            end

        end

    end

    return cite
end

return {
    { Meta = Meta },
    { Cite = Cite }
  }