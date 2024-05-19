--- unhighlight.lua – filter to unhighlight inline elements
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/unhighlight.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The unhighlight.lua is a Pandoc Lua filter that removes the 'mark' class from the inline elements.

function Span(span)
  if span.classes:includes 'mark' then
    return span.content
  end
end