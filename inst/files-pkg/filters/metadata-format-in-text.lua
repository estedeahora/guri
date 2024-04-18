--- metadata-format-in-text.lua – filter to include div elements (before the reference) in the output format
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/metadata-format-in-text.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local RawBlock = pandoc.RawBlock
local app = nil

-- Div(div) ------------------------------------------------------------------------------
-- Description: [en] Access pandoc.Div elements with class attribute "Paratext": (a) in latex generate environments of type
--                      "identifier"; (b) in Jats remove these elements from the body text (create empty elements of type 
--                      pandoc.RawBlock). For pandoc.Div whose identifier attribute is "app" store the content and its 
--                      position (for number appendices) in a table inside another table with all the appendicies.
--              [es] Accede a elementos pandoc.Div con atributo de clase "Paratext": (a) en latex genera entornos de tipo 
--                      "identifier"; (b) En Jats quitar estos elementos del cuerpo del texto (crea elementos vacío del tipo
--                      pandoc.RawBlock). Para los pandoc.Div cuyo atributo identifier es "app" se guarda el contenido y su 
--                      posición (para numerar apéndices) en una tabla dentro de otra tabla que contiene todos los apéndices.
-- Return: [en] In Latex a table with two elements of type pandoc.Rawblock defining an environment of type "div.identifier" 
--                with the Div inside. In Jats a pandoc.pandoc.RawBlock with no content (the element is deleted). In addition,
--                if the identifier attribute of the element is 'app' a table ('app') is generated which is used to transmit 
--                to Meta and which contains, for each appendix, a table with the content of the appendix and its position 
--                in the table.
--         [es] En Latex una tabla con dos elementos de tipo pandoc.Rawblock que definen un ambiente de tipo "div.identifier" 
--                con el Div dentro. En Jats un pandoc.pandoc.RawBlock sin contenido (se borra el elemento). Además, si el  
--                atributo identifier del elemento es 'app' se genera una tabla ('app') que se utiliza para transmitir a Meta 
--                y que contiene, para cada apéndice, una tabla con el contenido del apéndice y su posición en la tabla  

function Div(div)

    if(div.classes[1] == "Paratext") then
        
        if FORMAT:match 'jats' then
            if div.attr.attributes.app then

                if not app then
                    app = {}
                end
                
                table.insert(app, {content = div.content, N = #app + 1})

            else
                div = RawBlock('jats', '')
            end

        elseif FORMAT:match 'latex' or FORMAT:match 'pdf' then

            if  div.attr.attributes.app then
                 env = 'app'
            else
                env = div.identifier
            end

            div = {RawBlock('latex', '\\begin{'.. env .. '}'),
                   div, 
                   RawBlock('latex', '\\end{' .. env .. '}')}
        end
    
    end

    return div

end

-- Meta(m) ------------------------------------------------------------------------------
-- Description: [en]  When the output is Jats and there are appends, the appends are incorporated into 'meta.app'.
--              [es] Cuando la salida es Jats y hay apéndices, se incorpora los apéndices a 'meta.app'. 
-- Return: [en] A pandoc.Meta object where the 'app' table with the appendices (to be used later in jats template) 
--                is added (if it exists).
--         [es] Un objeto pandoc.Meta donde se agrega (si existe) la tabla 'app' con los apéndices (para usar luego 
--                en jats template).

function Meta(m)
    if(app) then
        m.app = app
    end
    return(m)
end