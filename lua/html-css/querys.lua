local M = {}

-- <link href="" rel="stylesheet" />
-- query for extracting href values from the page
-- this is general query for extracting information from
-- vue, svelte, html files.
-- this query extract links that ends with .css,.scss,.less or .sass extension.
-- So it will ignore the links like google fonts or what what ever you have in the link href tag
M.general_link_href = [[
	((tag_name) @tag (#eq? @tag "link")
	  (attribute
		(attribute_name) @attr_name (#eq? @attr_name "href")
		(quoted_attribute_value
		  ((attribute_value) @href_value (#match? @href_value "\\.css$|\\.less$|\\.scss$|\\.sass$")))))
]]

-- this query works for tsx and jsx
M.jsx_link_href = [[
	((identifier) @link (#eq? @link "link")
		(jsx_attribute
			(property_identifier) @href (#eq? @href "href")
			(string
				(string_fragment) @href_val)))
]]

-- M.selectors = [[
-- 	(id_selector
-- 		(id_name) @id_name)
-- 	(class_selector
-- 		(class_name) @class_name)
-- ]]

M.selectors = [[
(
 (rule_set
	 (selectors
		 (class_selector
			 (class_name) @class_name)
		 ) @class_decl
	 (#lua-match? @class_decl "^[.][a-zA-Z0-9_-]+$")
	 (#not-has-ancestor? @class_decl "media_statement")
	 (block) @class_block
	 )
 )
;; find nested class
;; (
;; (rule_set
;;	 (selectors
;;		 (class_selector
;;			 (class_name) @nested.class_name)
;;		 ) @nested.class_decl
;;	 (#lua-match? @nested.class_decl "^[.][a-zA-Z0-9_-]+$")
;;	 (#not-has-ancestor? @nested.class_decl "media_statement")
;;	 (block) @nested.class_block
;;	 ) @nested.rs (#has-ancestor? @nested.rs "rule_set")
;;)
(
 (rule_set
	 (selectors
		 (id_selector
			 (id_name) @id_name)
		 ) @id_decl
	 (#lua-match? @id_decl "^#[a-zA-Z0-9_-]+")
	 (#not-has-ancestor? @id_decl "media_statement")
	 (block) @id_block
	 )
 )
]]

M.internal_selectors = [[
	(id_selector
		(id_name) @id_name)
	(class_selector
		(class_name) @class_name)
]]

return M
