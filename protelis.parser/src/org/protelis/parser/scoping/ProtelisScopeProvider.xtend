/*
 * generated by Xtext 2.16.0
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
import org.eclipse.xtext.scoping.impl.MapBasedScope
import org.eclipse.xtext.scoping.impl.SimpleScope
import org.protelis.parser.protelis.Block
import org.protelis.parser.protelis.FunctionDef
import org.protelis.parser.protelis.VarDef
import org.protelis.parser.protelis.VarDefList
import org.protelis.parser.protelis.Lambda
import org.protelis.parser.protelis.Rep
import org.protelis.parser.protelis.Share
import org.protelis.parser.protelis.VarUse
import org.protelis.parser.protelis.ProtelisModule
import org.protelis.parser.protelis.Call

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ProtelisScopeProvider extends AbstractProtelisScopeProvider {
	
	override IScope getScope(EObject context, EReference reference) {
		if (context instanceof VarUse) {
			scope_VarUse_reference(context, reference)
		} else if (context instanceof Call) {
			var global = context.eContainer
			while (!(global instanceof ProtelisModule)) {
				global = global.eContainer
			}
			scope_Call_reference(global as ProtelisModule, reference)
		} else {
			super.getScope(context, reference)
		}
	}

	def IScope scope_VarUse_reference(VarUse expression, EReference ref) {
		val list = new ArrayList
		var container = expression.eContainer
	 	while (container !== null) {
			switch container {
				Block:
					if (container.first instanceof VarDef) {
						list.add(container.first as VarDef)
					}
				FunctionDef:
					if (container.args !== null) {
						list.addAll(container.args.args)
					}
				Lambda: {
					val lambdaArgs = container.args
					switch lambdaArgs {
						VarDef: list.add(lambdaArgs)
						VarDefList: list.addAll(lambdaArgs.args)
					}
				}
				Rep: list.add(container.init.x)
				Share: {
                    list.add(container.init.local)
                    list.add(container.init.field)
				}
				VarDef: list.add(container)
				ProtelisModule:
					return MapBasedScope.createScope(scope_Call_reference(container, ref), Scopes.scopeFor(list).allElements)
			}
			container = container.eContainer
		}
		Scopes.scopeFor(Collections.emptyList)
	}
	
	def IScope scope_Call_reference(ProtelisModule model, EReference ref) {
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
		if(javaImports !== null) {
			javaImports.importDeclarations.forEach[id |
				val type = id.importedType;
				type.eContents
					.filter[it instanceof JvmOperation]
					.map[it as JvmOperation]
					.filter[it.isStatic]
					.filter[if (id.wildcard) true else it.simpleName.equals(id.memberName)]
					.populateMethodReferences(java)
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
