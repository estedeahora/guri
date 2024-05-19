--- language-elements.lua – filter to define the language of the element titles
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/language-elements.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The language-elements.lua is a Pandoc Lua filter that defines the language of the element 
-- titles.

local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower

local function tocode(lang)
    return lower(stringify(lang)):match('^[a-z][a-z][a-z]*')
end

local function babel_language(lang_iso)
    
    local dic = {
        af  = "afrikaans",
        am  = "amharic",
        ar  = "arabic",
        as  = "assamese",
        ast = "asturian",
        bg  = "bulgarian",
        bn  = "bengali",
        bo  = "tibetan",
        br  = "breton",
        ca  = "catalan",
        cy  = "welsh",
        cs  = "czech",
        cop = "coptic",
        da  = "danish",
        dv  = "divehi",
        el  = "greek",
        en  = "english",
        eo  = "esperanto",
        es  = "spanish",
        et  = "estonian",
        eu  = "basque",
        fa  = "persian",
        fi  = "finnish",
        fr  = "french",
        fur = "friulan",
        ga  = "irish",
        gd  = "scottish",
        gez = "ethiopic",
        gl  = "galician",
        gu  = "gujarati",
        he  = "hebrew",
        hi  = "hindi",
        hr  = "croatian",
        hu  = "magyar",
        hy  = "armenian",
        ia  = "interlingua",
        id  = "indonesian",
        ie  = "interlingua",
        is  = "icelandic",
        it  = "italian",
        ja  = "japanese",
        km  = "khmer",
        kmr = "kurmanji",
        kn  = "kannada",
        ko  = "korean",
        la  = "latin",
        lo  = "lao",
        lt  = "lithuanian",
        lv  = "latvian",
        ml  = "malayalam",
        mn  = "mongolian",
        mr  = "marathi",
        nb  = "norsk",
        nl  = "dutch",
        nn  = "nynorsk",
        no  = "norsk",
        nqo = "nko",
        oc  = "occitan",
        ['or']  = "oriya",
        pa  = "punjabi",
        pl  = "polish",
        pms = "piedmontese",
        pt  = "portuguese",
        rm  = "romansh",
        ro  = "romanian",
        ru  = "russian",
        sa  = "sanskrit",
        se  = "samin",
        sk  = "slovak",
        sq  = "albanian",
        sr  = "serbian",
        sv  = "swedish",
        syr = "syriac",
        ta  = "tamil",
        te  = "telugu",
        th  = "thai",
        ti  = "ethiopic",
        tk  = "turkmen",
        tr  = "turkish",
        uk  = "ukrainian",
        ur  = "urdu",
        vi  = "vietnamese",
        zh = "chinese-hans"
    }

    return dic[lang_iso] 
end

function Meta(meta)
    
    if meta.metadata_lang then
        for _, metadata_lang_i in ipairs(meta.metadata_lang) do
            local lang = tocode(metadata_lang_i.lang)
            metadata_lang_i['lang-babel'] = babel_language(lang)
        end
    end

    meta.journal['lang-babel'] = babel_language(tocode(meta.journal['lang']))

    return meta
end


