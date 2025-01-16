local querys = {}

querys.href = [[
((tag_name) @tag (#eq? @tag "link")
	  (attribute
		(attribute_name) @attr_name (#eq? @attr_name "href")
		(quoted_attribute_value
		  ((attribute_value) @href_value (#match? @href_value "\\.css$|\\.less$|\\.scss$|\\.sass$")))))
]]

return querys
