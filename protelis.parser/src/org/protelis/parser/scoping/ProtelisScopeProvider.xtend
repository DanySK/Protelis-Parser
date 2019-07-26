/*
 * generated by Xtext 2.16.0
 */
package org.protelis.parser.scoping

import com.google.inject.Inject
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.common.types.JvmFeature
import org.eclipse.xtext.common.types.util.TypeReferences
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

import static extension org.protelis.parser.ProtelisExtensions.callableEntities
import static extension org.protelis.parser.ProtelisExtensions.callableEntitiesNamed

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ProtelisScopeProvider extends AbstractProtelisScopeProvider {
	
	@Inject 
	TypeReferences references;

	val automaticallyImported = #[
			typeof(Math),
			typeof(Double)
		]
		.filter[it !== null]
		.toList

	override IScope getScope(EObject context, EReference reference) {
		switch(context) {
			VarUse: scopeVar(context, reference)
			Call: {
				var global = context.eContainer
				while (!(global instanceof ProtelisModule)) {
					global = global.eContainer
				}
				scopeCall(global as ProtelisModule, reference)
			}
			default: super.getScope(context, reference)
		}
	}

	private def Iterable<VarDef> extractReferences(EObject container) {
		switch container {
			VarDef:
				#[container]
			Block:
				container.statements.flatMap[extractReferences]
//				if(container.first instanceof VarDef) #[container.first as VarDef] else emptyList
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
//				val result = new ArrayList
//				while (body !== null) {
//					result.addAll(extractReferences(body))
//					body = body.next
//				}
//				result
				body.extractReferences
			}
			default:
				emptyList
		}
	}

	def IScope scopeVar(VarUse expression, EReference ref) {
		val list = new ArrayList<VarDef>
		var container = expression.eContainer
		while (container !== null) {
			switch container {
				ProtelisModule:
					return MapBasedScope.createScope(scopeCall(container, ref),
						Scopes.scopeFor(list).allElements)
				default:
					list.addAll(extractReferences(container))
			}
			container = container.eContainer
		}
		Scopes.scopeFor(Collections.emptyList)
	}

	def IScope scopeCall(ProtelisModule model, EReference ref) {
		val List<FunctionDef> internal = new ArrayList(model.definitions)
		val importDeclarations = model?.imports?.importDeclarations
		val Iterable<IEObjectDescription> externalProtelis = importDeclarations
			?.filter[it instanceof ProtelisImport]
			?.map[it as ProtelisImport]
			?.map[it.module]
			?.flatMap[ module |
				module.definitions.filter[public]
					.flatMap[#[
						generateDescription(it.name, it),
						generateDescription(module.name + ":" + it.name, it)
					]]
			]
			?.toList
			?: emptyList
		val Iterable<JvmFeature> autoImportedTypes = (
				#[references.findDeclaredType("org.protelis.Builtins", model)].filter[it !== null]
				+ automaticallyImported.map[references.findDeclaredType(it, model)]
			)
			.flatMap[callableEntities]
		val Iterable<JvmFeature> externalJava = importDeclarations
				?.filter[it instanceof JavaImport]
				?.map[it as JavaImport]
				?.flatMap[
					if (it.wildcard) {
						it.importedType.callableEntities
					} else {
						it.importedType.callableEntitiesNamed(it.importedMemberName)
					}
				]
				?: emptyList
		val callableJava = (externalJava + autoImportedTypes)
			.flatMap[#[
				generateDescription(it.simpleName, it),
				generateDescription(it.qualifiedName.replace(".", "::"), it)
			]]
		val plainProtelis = Scopes.scopeFor(internal)
		val refJava = new SimpleScope(callableJava)
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
