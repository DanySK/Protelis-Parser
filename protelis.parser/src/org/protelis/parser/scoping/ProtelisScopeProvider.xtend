/*
 * generated by Xtext
 */
package org.protelis.parser.scoping

import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.eclipse.xtext.scoping.impl.MapBasedScope
import org.eclipse.xtext.scoping.impl.SimpleScope
import org.protelis.parser.protelis.Block
import org.protelis.parser.protelis.FunctionDef
import org.protelis.parser.protelis.Module
import org.protelis.parser.protelis.VarDef
import org.protelis.parser.protelis.VarDefList
import org.protelis.parser.protelis.Lambda
import org.protelis.parser.protelis.Rep
import org.protelis.parser.protelis.VarUse

/**
 * This class contains custom scoping description.
 * 
 * see : http://www.eclipse.org/Xtext/documentation.html#scoping
 * on how and when to use it 
 *
 */
class ProtelisScopeProvider extends AbstractDeclarativeScopeProvider {

	def IScope scope_VarUse_reference(VarUse expression, EReference ref) {
		val list = new ArrayList
		var container = expression.eContainer
	 	while (container != null) {
			switch container {
				Block:
					if (container.first instanceof VarDef) {
						list.add(container.first)
					}
				FunctionDef:
					if (container.args != null) {
						list.addAll(container.args.args)
					}
				Lambda: {
					val lambdaArgs = container.args
					switch lambdaArgs {
						VarDef: list.add(lambdaArgs)
						VarDefList: list.addAll((lambdaArgs as VarDefList).args)
					}
				}
				Rep: list.add(container.init.x)
				VarDef: list.add(container)
				Module:
					return MapBasedScope.createScope(scope_Call_reference(container, ref), Scopes.scopeFor(list).allElements)
			}
			container = container.eContainer
		}
		Scopes.scopeFor(Collections.emptyList)
	}
	
	def IScope scope_Call_reference(Module model, EReference ref) {
		val List<EObject> internal = new ArrayList(model.definitions)
		val List<IEObjectDescription> externalProtelis = new ArrayList
		val List<IEObjectDescription> java = new ArrayList
		model.protelisImport.forEach[ 
			val moduleName = it.module.name
			it.module.definitions.filter[public].forEach[
				externalProtelis.add(generateDescription(it.name, it))
				externalProtelis.add(generateDescription(moduleName + ":" + it.name, it))
			]
		]
		val javaImports = model.javaimports
		if(javaImports != null) {
			javaImports.importDeclarations.forEach[id |
				val type = id.importedType
				if(id.wildcard) {
					type.declaredOperations.filter[it.isStatic].populateMethodReferences(java)
				} else {
					val methodName = id.memberName
					type.declaredOperations.filter[it.isStatic]
						.filter[it.simpleName.equals(methodName)]
						.populateMethodReferences(java)
				}
			]
		}
		val plainProtelis = Scopes.scopeFor(internal)
		val refJava = new SimpleScope(java)
		/*
		 * Search locally => search Protelis imports => search Java imports
		 */
		val outer = MapBasedScope.createScope(refJava, externalProtelis)
		val final = MapBasedScope.createScope(outer, plainProtelis.allElements)
		final
	}
	
	def static populateMethodReferences(Iterable<JvmOperation> source, Collection<IEObjectDescription> destination) {
		source.forEach[
			destination.add(generateDescription(it.simpleName, it))
			destination.add(generateDescription(it.qualifiedName.replace(".", "::"), it))
		]
	}
	
	def static generateDescription(String name, EObject obj) {
		val ref = QualifiedName.create(name)
		EObjectDescription.create(ref, obj)
	}

}
