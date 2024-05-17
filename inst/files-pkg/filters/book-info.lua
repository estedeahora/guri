--- book-info – Modifies the content of 'meta.book_info.text' to be of type Inlines.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/book-info.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Modifies the content of 'meta.book_info.text' to be of type Inlines
--                     (not Blocks, since <product> does not accept <p> elements as content).
--				[es] Modifica el contenido de 'meta.book_info.text' para que sea de tipo Inlines
--                     (no Blocks, ya que <product> no acepta elementos <p> como contenido).
-- Return: [en] Modified meta, with 'meta.book_info.text' of type Inlines.
--		   [es] Meta modificado, con 'meta.book_info.text' de tipo Inlines.

function Meta(meta)

    if meta.book_info then
        
        local cosa = meta.book_info.text[1].content
        
        meta.book_info.text = (cosa)

    end

    return meta
end
