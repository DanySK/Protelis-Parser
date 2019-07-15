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
import org.eclipse.xtext.common.types.JvmFeature
import org.eclipse.xtext.common.types.JvmField
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.MapBasedScope
import org.eclipse.xtext.scoping.impl.SimpleScope
import org.protelis.parser.protelis.Block
import org.protelis.parser.protelis.Call
import org.protelis.parser.protelis.FunctionDef
import org.protelis.parser.protelis.JavaImport
import org.protelis.parser.protelis.Lambda
import org.protelis.parser.protelis.ProtelisImport
import org.protelis.parser.protelis.ProtelisModule
import org.protelis.parser.protelis.Rep
import org.protelis.parser.protelis.Share
import org.protelis.parser.protelis.VarDef
import org.protelis.parser.protelis.VarDefList
import org.protelis.parser.protelis.VarUse
import org.protelis.parser.protelis.Yield

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

	private def Iterable<VarDef> extractReferences(EObject container) {
		switch container {
			Block:
				if(container.first instanceof VarDef) #[container.first as VarDef] else emptyList
			FunctionDef:
				container.args?.args ?: emptyList
			Lambda: {
				val lambdaArgs = container.args
				switch lambdaArgs {
					VarDef: #[lambdaArgs]
					VarDefList: lambdaArgs.args
					default: emptyList
				}
			}
			Rep:
				#[container.init.x]
			Share: {
				val init = container.init
				#[container.init.field] + if(init.local === null) #[] else #[init.local]
			}
			Yield: {
				val parent = container.eContainer
				var Block body = switch parent {
					Rep: parent.body
					Share: parent.body
				}
				// Get to the last instruction and scan the whole block
				val result = new ArrayList
				while (body !== null) {
					result.addAll(extractReferences(body))
					body = body.next
				}
				result
			}
			default:
				emptyList
		}
	}

	def IScope scope_VarUse_reference(VarUse expression, EReference ref) {
		val list = new ArrayList<VarDef>
		var container = expression.eContainer
		while (container !== null) {
			switch container {
				ProtelisModule:
					return MapBasedScope.createScope(scope_Call_reference(container, ref),
						Scopes.scopeFor(list).allElements)
				default:
					list.addAll(extractReferences(container))
			}
			container = container.eContainer
		}
		Scopes.scopeFor(Collections.emptyList)
	}

	def IScope scope_Call_reference(ProtelisModule model, EReference ref) {
		val List<EObject> internal = new ArrayList(model.definitions)
		val List<IEObjectDescription> externalProtelis = new ArrayList
		val List<IEObjectDescription> executables = new ArrayList
		model?.imports?.importDeclarations?.forEach [ import |
			if (import instanceof ProtelisImport) {
				val moduleName = import.module.name
				import.module.definitions.filter[public].forEach [
					externalProtelis.add(generateDescription(it.name, it))
					externalProtelis.add(generateDescription(moduleName + ":" + it.name, it))
				]
			} else if (import instanceof JavaImport) {
				val type = import.importedType;
				type.eContents.filter[it instanceof JvmField || it instanceof JvmOperation].map[it as JvmFeature].filter [
					it.isStatic
				].filter[it.visibility == JvmVisibility.PUBLIC].filter [
					import.wildcard || it.simpleName == import.importedMemberName
				].populateMethodReferences(executables)
			}
		]
		val plainProtelis = Scopes.scopeFor(internal)
		val refJava = new SimpleScope(executables)
		/*
		 * Search locally => search Protelis imports => search Java imports
		 */
		val outer = MapBasedScope.createScope(refJava, externalProtelis)
		val final = MapBasedScope.createScope(outer, plainProtelis.allElements)
		final
	}

	def static populateMethodReferences(Iterable<JvmFeature> source, Collection<IEObjectDescription> destination) {
		source.forEach [
			destination.add(generateDescription(it.simpleName, it))
			destination.add(generateDescription(it.qualifiedName.replace(".", "::"), it))
		]
	}

	def static generateDescription(String name, EObject obj) {
		val ref = QualifiedName.create(name)
		EObjectDescription.create(ref, obj)
	}

}
