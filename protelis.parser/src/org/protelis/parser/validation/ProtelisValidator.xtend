package org.protelis.parser.validation

import org.eclipse.xtext.validation.Check
import org.protelis.parser.protelis.Block
import org.protelis.parser.protelis.FunctionDef
import org.protelis.parser.protelis.Lambda
import org.protelis.parser.protelis.ProtelisPackage
import org.protelis.parser.protelis.VarDef
import org.protelis.parser.protelis.VarDefList

/**
 * Custom validation rules. 
 *
 * see http://www.eclipse.org/Xtext/documentation.html#validation
 */
class ProtelisValidator extends AbstractProtelisValidator {

	/**
	 * Make sure that nobody defined the variable already:
	 * 
	 * other previous lets;
	 * 
	 * containing function;
	 * 
	 * containing lambda;
	 * 
	 * containing rep
	 */
	@Check
	def letNameDoesNotShadowArguments(VarDef exp) {
		var parent = exp.eContainer
		while (parent !== null) {
			if (parent instanceof Block) {
				if (parent.first instanceof VarDef && parent.first != exp) {
					val otherLet = parent.first as VarDef
					if (otherLet.name.equals(exp.name)) {
						print("CAIONE")
						error(exp)
					}
				}
			}
			if (parent instanceof FunctionDef) {
				if(parent.args !== null){
					if(parent.args.args.map[it.name].contains(exp.name)){
						error(exp)
					}
				}
			}
			if (parent instanceof Lambda) {
				if(parent.args !== null) {
					val args = parent.args;
					if(args instanceof VarDef){
						if (args.name.equals(exp.name)) {
							error(exp)
						}
					} else if (args instanceof VarDefList) {
						if (args.args.map[it.name].contains(exp.name)) {
							error(exp)
						}
					}
				}
			}
			parent = parent.eContainer
		}
	}
	
	def error(VarDef exp)  {
		val error = "The variable has already been defined in this context. Pick another name."
		if (exp.eContainer instanceof Block) {
			error(error, exp.eContainer, ProtelisPackage.Literals.BLOCK__FIRST)
		}
	}

}
