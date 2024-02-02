--- unhighlight.lua – filter to unhighlight inline elements
--- https://github.com/estedeahora/guri/tree/main/files/filters/unhighlight.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

function Span(span)
  if span.classes:includes 'mark' then
    return span.content
  end
end