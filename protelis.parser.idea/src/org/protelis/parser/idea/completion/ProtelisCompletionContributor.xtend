/*
 * generated by Xtext 2.10.0
 */
package org.protelis.parser.idea.completion

import org.eclipse.xtext.idea.lang.AbstractXtextLanguage
import org.protelis.parser.idea.lang.ProtelisLanguage

class ProtelisCompletionContributor extends AbstractProtelisCompletionContributor {
	new() {
		this(ProtelisLanguage.INSTANCE)
	}
	
	new(AbstractXtextLanguage lang) {
		super(lang)
		//custom rules here
	}
}
