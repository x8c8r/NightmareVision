package extensions.hscript;

import crowplexus.hscript.Parser;
import crowplexus.hscript.*;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;

using crowplexus.hscript.Tools;

using StringTools;

/**
 * Extended to read the `public` keyword.
 */
class ParserEx extends Parser
{
	override function parseStructure(id)
	{
		#if hscriptPos
		var p1 = tokenMin;
		#end
		
		return switch (id)
		{
			case "public":
				final e = parseExpr();
				
				switch (e.expr())
				{
					case EVar(name, _), EFunction(_, _, name) if (name != null):
						mk(EMeta(':sharable', [], e), tokenMin, tokenMax);
					default:
						unexpected(TId(id));
				}
				
			default:
				super.parseStructure(id);
		}
	}
}
