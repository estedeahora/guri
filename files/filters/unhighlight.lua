--- unhighlight.lua – filter to modify
--- https://github.com/estedeahora/guri/tree/main/files/filters/unhighlight.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

function Span(span)
  if span.classes:includes 'mark' then
    return span.content
  end
end