--- language-elements.lua – filter to define the language of the element titles
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/language-elements.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The language-elements.lua is a Pandoc Lua filter that defines the language of the element 
-- titles (abstract, keywords, tables, figures, sources, notes, references, credit,
-- acknowledgements, funding, data availability, conflicts of interest). The filter uses the
-- language of the article to define the titles of the elements. If the language of the article
-- is different from the language of the journal, it is modified. The filter also uses custom
-- values for the titles of the elements if they are provided. The filter also modifies the
-- metadata to add the title of the abstract and keywords in the metadata_lang elements.

local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower

local lang
local translate

local function tocode(lang)
    return lower(stringify(lang):match('^..'))
end

local dic = {
    en = {abstract = 'Abstract',        kw = 'Keywords',         TAB = 'Table',   FIG = 'Figure',     source = 'Source', note = 'Note',      ref = 'References'                },
    es = {abstract = 'Resumen',         kw = 'Palabras claves',  TAB = 'Tabla',   FIG = 'Figura',     source = 'Fuente', note = 'Nota',      ref = 'Referencias bibliográficas'},
    pt = {abstract = 'Resumo',          kw = 'Palavras chave',   TAB = 'Tabela',  FIG = 'Figura',     source = 'Fonte',  note = 'Nota',      ref = 'Referências'               },
    fr = {abstract = 'Résumé',          kw = 'Mots clés',        TAB = 'Tableau', FIG = 'Figure',     source = 'Source', note = 'Notes',     ref = 'Bibliographie'             },
    it = {abstract = 'Sommario',        kw = 'Parole chiave',    TAB = 'Tabella', FIG = 'Figura',     source = 'Fonte',  note = 'Nota',      ref = 'Riferimenti bibliografici' },
    de = {abstract = 'Zusammenfassung', kw = 'Schlüsselwörter ', TAB = 'Tabelle', FIG = 'Abbildung',  source = 'Quelle', note = 'Anmerkung', ref = 'Literatur'                 },
    zh = {abstract = '摘要',            kw = '关键词',            TAB = '表',      FIG = '图',         source = '来源',    note = '备注',      ref = '参考文献'                   }, -- Chino simplificado
    la = {abstract = 'Summarium',       kw = 'Keywords',         TAB = 'Tabula',  FIG = 'Descriptio', source = 'Source', note = 'Note',      ref = 'References'                }  -- Latin (for Lorem Itsum in 'example')
  }

local dic_paratext = {
    en = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Acknowledgements', funding = 'Funding statement',              data = 'Data availability statement', coi = "Conflicts of Interest Statement"},
    es = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Agradecimientos',  funding = 'Declaración de financiamiento',  data = 'Disponibilidad de datos',     coi = "Declaración de conflictos de intereses"},
    pt = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Reconhecimentos',  funding = 'Declaração de financiamento',    data = 'Disponibilidade de dados',    coi = "Declaração de conflitos de interesses"},
    fr = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Remerciements',    funding = 'Déclaration de financement',     data = 'Disponibilité des données',   coi = "Déclaration de conflits d'intérêts"},
    it = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Ringraziamenti',   funding = 'Dichiarazione di finanziamento', data = 'Disponibilità dei dati',      coi = "Dichiarazione di conflitti di interesse"},
    de = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Danksagungen',     funding = 'Finanzierungserklärung',         data = 'Datenverfügbarkeit',          coi = "Erklärung von Interessenkonflikten"},
    zh = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = '致谢',             funding = '供资说明',                        data = '数据可用性',                   coi = "利益冲突声明"},
    la = {credit = 'CRediT (Contributor Roles Taxonomy)', ack = 'Agnitiones',       funding = 'Funding statement',              data = 'Data availability statement', coi = "Disclosure statement"}
  }

local custom_titles = {
    {m = 'abstract-title',   k = 'abstract_title',   v = 'abstract'},
    {m = 'keyword-title',    k = 'keyword_title',    v = 'kw'},
    {m = 'table-title',      k = 'table_title',      v = 'TAB',     float = true},
    {m = 'figure-title',     k = 'figure_title',     v = 'FIG',     float = true},
    {m = 'source-title',     k = 'none',             v = 'source',  float = true},
    {m = 'note-title',       k = 'none',             v = 'note',    float = true},
    {m = 'references-title', k = 'references_title', v = 'ref'},
    {m = 'credit-title',     k = 'credit_title',     v = 'credit'},
    {m = 'ack-title',        k = 'ack_title',        v = 'ack',     statement = true},
    {m = 'funding-title',    k = 'funding_title',    v = 'funding', statement = true},
    {m = 'data-title',       k = 'data_title',       v = 'data',    statement = true},
    {m = 'coi-title',        k = 'coi_title',        v = 'coi',     statement = true}  
  }

local dic_date = {
    en = {received = 'Received', accepted = 'Accepted',   epub = 'Published online'},
    es = {received = 'Recibido', accepted = 'Aceptado',   epub = 'Publicacdo en línea'},
    pt = {received = 'Recebido', accepted = 'Aceito',     epub = 'Publicado on-line'},
    fr = {received = 'Reçu',     accepted = 'Accepté',    epub = 'Publié en ligne'},
    it = {received = 'Ricevuto', accepted = 'Accettato',  epub = 'Pubblicato in linea'},
    de = {received = 'Erhalten', accepted = 'Akzeptiert', epub = 'Online veröffentlicht'}, 
    zh = {received = 'Received', accepted = 'Accepted',   epub = 'Published online'},
    la = {received = 'Received', accepted = 'Accepted',   epub = 'Published online'}
  }

-- add_metatitle(meta_i) -----------------------------------------------------------------------
-- Description: [en] Take a metadata element and define the title of the abstract and the kw 
--                     (use custom values if available).
--              [es] Toma un elemento de metadatos y define el título del abstract y las kw 
--                      (usa valores personalizados si hubiere).
-- Return: [en] A table with the metadata adding the abstract title and kw.
--         [es] Una tabla con los metadatos agregando el título de abstract y kw.

function add_metatitle(meta_i)
    -- local lang_i = lower(stringify(meta_i.lang):match('^..') )
    local lang_i = tocode(meta_i.lang)
    local dic_i = dic[lang_i]

    if not meta_i.abstract_title and dic_i then
        meta_i.abstract_title = dic_i.abstract
    end

    if not meta_i.keyword_title and dic_i then
        meta_i.keyword_title = dic_i.kw
    end

    if not meta_i.abstract_title or not meta_i.keyword_title then
        error('ERROR:  Title for the abstract and keywords must be provided ' .. 
                '(language: ' .. lang_i .. ')\n')
    end
    
    return(meta_i)
end

-- Meta(meta) --------------------------------------------------------------------------------------
-- Description: [en] Defines the element titles and metadata of the article according to the language 
--                     (in main and secondary languages). If the language of the article is different 
--                     from the language of the journal, it is modified. 
--              [es] Define los títulos de los elemento y metadatos del artículo en función del idioma
--                     (en idioma principal y idiomas secundarios). Si el lenguaje del artículo es diferente
--                     del lenguaje de la revista se modifica. 
-- Return: [en] Modified 'Meta'. Element titles (taking custom elements if any) are added to 'meta'. 
--                In addition, metadata_lang is modified to add abstract title and kw. 
--         [en] 'Meta' modificado. Se agrega a 'meta' los títulos de los elementos (tomando los elementos
--                personalizados si hubiera). Además, se modifica metadata_lang para agregar título de abstract y kw. 

function Meta(meta)
    
    -- Modify the journal's default language for the article.
    meta.journal.lang = meta.lang

    if meta.customized and stringify(meta.customized['artic-lang']) ~= meta.lang then
        warn("NOTE: The article uses a different main language than the journal.\n")
        meta.lang = meta.customized['artic-lang']
    end
    
    -- Titles of elements in the main language of the article (translate)    
    lang = tocode(meta.lang)
    translate = dic[lang] or {}

    -- Titles of elements in the main language of the journal (translate_journal)
    lang_journal = tocode(meta.journal.lang)
    translate_journal = dic_paratext[lang_journal] or {}

    -- Add all elements from translate_journal to translate
    for k, el in pairs(translate_journal) do
        if el then
           translate[k] = el
        end
    end

    meta.floats = {}

    for _, t in ipairs(custom_titles)  do
            
        if meta.customized and meta.customized[t.k] then
            -- meta.customized['k'] -> to -> translate['v']
            translate[t.v] = meta.customized[t.k]
        end

        -- translate['v'] -> to -> meta['m'] / meta.floats['m'] / meta.staments['m']
        if translate[t.v] then
            if t.float then
                meta.floats[t.m] = translate[t.v]
            elseif t.statement then
                if  meta.statements and meta.statements[t.v] then
                    -- meta.statements[t.m] = meta.statements[t.v]
                    meta.statements[t.m] = translate[t.v]
                end
            else
                meta[t.m] = translate[t.v]
            end
        else
            error('ERROR: The customized "' ..  t.k .. '" element must be provided ' .. 'for the "' .. lang .. '" language.\n')
        end
    end
    
    -- Abstract / kw secondary languages 
    if(meta.metadata_lang) then
        for k, meta_i in ipairs(meta.metadata_lang) do
            meta.metadata_lang[k] = add_metatitle(meta_i) 
        end
    end

    -- History type names
    if(meta.history) then
        for _, history in ipairs(meta.history) do
            history['type-title'] = dic_date[lang_journal][stringify(history.type)]
        end
    end

    return meta

end


