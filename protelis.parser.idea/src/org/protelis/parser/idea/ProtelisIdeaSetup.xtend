/*
 * generated by Xtext 2.10.0
 */
package org.protelis.parser.idea

import org.eclipse.xtext.ISetup
import org.eclipse.xtext.idea.extensions.EcoreGlobalRegistries

class ProtelisIdeaSetup implements ISetup {

	override createInjectorAndDoEMFRegistration() {
		EcoreGlobalRegistries.ensureInitialized
		new ProtelisStandaloneSetupIdea().createInjector
	}

}
