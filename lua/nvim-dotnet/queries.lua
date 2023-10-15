
local queries = {

}


queries.TestResult = [[((element
   [(STag
	((Name) @name (#eq? @name "UnitTestResult")
	(Attribute (
		(Name) @attrName (#eq? @attrName "testName")
		(AttValue) @testName
		))
	(Attribute (
		(Name) @resultName (#eq? @resultName "outcome")
		(AttValue) @testResult
		))
	))
     (EmptyElemTag
	((Name) @name (#eq? @name "UnitTestResult")
	(Attribute (
		(Name) @attrName (#eq? @attrName "testName")
		(AttValue) @testName
		))
	(Attribute (
		(Name) @resultName (#eq? @resultName "outcome")
		(AttValue) @testResult
		))
	))
]))]]

queries.namespace_class = [[
[((namespace_declaration
 ((qualified_name) @namespace
  ((declaration_list
     ((class_declaration
      (identifier) @classname
	((declaration_list) @decl)
      ))
  ))
 )
))
((file_scoped_namespace_declaration
 ((qualified_name) @namespace)
 ((class_declaration
    ((identifier) @classname
	((declaration_list) @decl)
    )
  ))
))]
]]

queries.methods = [[
((local_function_statement
  ((identifier) @methodname)
))
]]

queries.projectReferences = [[
[(element
	((EmptyElemTag
		((Name) @packageReferenceName (#eq? @packageReferenceName "PackageReference"))
		((Attribute
			((Name) @includeName (#eq? @includeName "Include"))
			((AttValue) @packageName)
		   ))
		((Attribute
			((Name) @versionName (#eq? @versionName "Version"))
			((AttValue) @packageVersion)
		   ))
	   ))
   )
(element
	((STag
		((Name) @packageReferenceName (#eq? @packageReferenceName "PackageReference"))
		((Attribute
			((Name) @includeName (#eq? @includeName "Include"))
			((AttValue) @attributeValue)
		   ))
		((Attribute
			((Name) @versionName (#eq? @versionName "Version"))
			((AttValue) @packageVersion)
		   ))
	   ))
  )
 ]
]]


queries.method_parameters = [[
((parameter
	((identifier) @name)
))]]


queries.method_return_type = [[
((method_declaration
	((predefined_type) @return_type)
   ))
]]

return queries;
