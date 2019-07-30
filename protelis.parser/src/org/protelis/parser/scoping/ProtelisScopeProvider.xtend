/*
 * generated by Xtext 2.16.0
 */
package org.protelis.parser.scoping

import com.google.inject.Inject
import java.util.ArrayList
import java.util.Collection
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
import org.protelis.parser.protelis.Declaration
import org.protelis.parser.protelis.FunctionDef
import org.protelis.parser.protelis.ImportDeclaration
import org.protelis.parser.protelis.JavaImport
import org.protelis.parser.protelis.LongLambda
import org.protelis.parser.protelis.OldLongLambda
import org.protelis.parser.protelis.OldShortLambda
import org.protelis.parser.protelis.ProtelisImport
import org.protelis.parser.protelis.ProtelisModule
import org.protelis.parser.protelis.Rep
import org.protelis.parser.protelis.Share
import org.protelis.parser.protelis.VarDef
import org.protelis.parser.protelis.VarDefList
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
		switch (context) {
			ImportDeclaration: super.getScope(context, reference)
			default: context.scope
		}
	}

	private def IScope scope(EObject source) {
		switch (source) {
			LongLambda: source.makeScope(source.args)
			OldLongLambda: source.makeScope(source.args)
			OldShortLambda: source.makeScope(#[source.singleArg])
			FunctionDef: source.makeScope(source.args)
			Block: source.makeScope(source.allDefinitions)
			ProtelisModule: source.scopeCall
			Rep: source.makeScope(#[source.init.x])
			Share: {
				val init = source.init
				source.makeScope(#[init.field] + if(init.local === null) #[] else #[init.local])
			}
			Yield: {
				val parent = source.eContainer
				var Block body = switch parent {
					Rep: parent.body
					Share: parent.body
				}
				source.makeScope(body.allDefinitions)
			}
			default: source.eContainer?.scope ?: Scopes.scopeFor(emptyList)
		}
	}

	private static def Iterable<VarDef> allDefinitions(Block block) {
		block.statements
			.filter[it instanceof Declaration]
			.map[it as Declaration]
			.map[it.name]
	}

	private def IScope makeScope(EObject context, Iterable<VarDef> source) {
		makeScope(context.eContainer.scope, source)
	}
	private def IScope makeScope(EObject source, VarDefList vars) {
		makeScope(source.eContainer.scope, vars?.args ?: emptyList)
	}
	private static def IScope makeScope(IScope parent, Iterable<VarDef> source) {
		if (parent === null) {
			Scopes.scopeFor(source)
		} else {
			source.isEmpty ? parent : Scopes.scopeFor(source, parent)
		}
	}
	def private static <T extends EObject> Iterable<IEObjectDescription> elementsOf(Iterable<T> source, (T)=>String name, (T)=>String qualifiedName) {
		if (qualifiedName === null) {
			source.map[ generateDescription(name.apply(it), it) ]
		} else {
			source.flatMap[ #[
				generateDescription(name.apply(it), it),
				generateDescription(qualifiedName.apply(it), it)
				]
			]
		}
	}

	def IScope scopeCall(ProtelisModule model) {
		val List<FunctionDef> internal = new ArrayList(model.definitions)
		val importDeclarations = model?.imports?.importDeclarations
		val Iterable<IEObjectDescription> externalProtelis = importDeclarations
			?.filter[it instanceof ProtelisImport]
			?.map[it as ProtelisImport]
			?.map[it.module]
			?.flatMap[ module |
				module.definitions
					.filter[public]
					.elementsOf([it.name], [module.name + ":" + it.name])
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
		/*
		 * Search locally => search Protelis imports => search Java imports
		 */
		Scopes.scopeFor(internal, MapBasedScope.createScope(new SimpleScope(callableJava), externalProtelis))
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
