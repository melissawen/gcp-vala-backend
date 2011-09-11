/*
 * This file is part of gedit-code-assistant.
 *
 * Copyright (C) 2011 - Jesse van den Kieboom
 *
 * gedit-code-assistant is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * gedit-code-assistant is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with gedit-code-assistant.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

namespace Gcp.C
{

class Document : Gcp.Document,
                 SymbolBrowserSupport,
                 DiagnosticSupport,
                 SemanticValueSupport
{
	private class CursorWrapper
	{
		public CX.Cursor cursor;

		public CursorWrapper(CX.Cursor c)
		{
			cursor = c;
		}

		public bool equal(CursorWrapper other)
		{
			return cursor.equal(other.cursor);
		}

		public uint hash()
		{
			return cursor.hash();
		}
	}

	public DiagnosticTags tags {get; set;}

	private TranslationUnit d_tu;
	private SymbolBrowser d_symbols;
	private SourceIndex<Diagnostic> d_diagnostics;
	private HashMap<CursorWrapper, SemanticValue> d_semanticsMap;
	private SourceIndex<SemanticValue> d_semantics;

	public Document(Gedit.Document document)
	{
		base(document);

		d_tu = new TranslationUnit();
		d_symbols = new SymbolBrowser();
		d_diagnostics = new SourceIndex<Diagnostic>();
		d_semantics = new SourceIndex<SemanticValue>();

		d_tu.update.connect(on_tu_update);
	}

	public SymbolBrowser symbol_browser
	{
		get
		{
			return d_symbols;
		}
	}

	public SourceIndex<Diagnostic> diagnostics
	{
		get { return d_diagnostics; }
	}

	public SourceIndex<SemanticValue> semantics
	{
		get { return d_semantics; }
	}

	public TranslationUnit translation_unit
	{
		get
		{
			return d_tu;
		}
	}

	private void clip_location(SourceLocation location)
	{
		if (location.line > document.get_line_count())
		{
			location.line = document.get_line_count();
		}
	}

	private void update_diagnostics(CX.TranslationUnit tu)
	{
		d_diagnostics.clear();

		for (uint i = 0; i < tu.num_diagnostics; ++i)
		{
			CX.Diagnostic d = tu.get_diagnostic(i);

			Diagnostic.Severity severity = Translator.severity(d.severity);

			var loc = Translator.source_location(d.location);

			if (loc.file == null || !loc.file.equal(location))
			{
				continue;
			}

			clip_location(loc);

			LinkedList<SourceRange> ranges = new LinkedList<SourceRange>();

			for (uint j = 0; j < d.num_ranges; ++j)
			{
				SourceRange range = Translator.source_range(d.get_range(j));

				if (range.start.file != null &&
				    range.end.file != null &&
				    range.start.file.equal(location) &&
				    range.end.file.equal(location))
				{
					clip_location(range.start);
					clip_location(range.end);

					ranges.add(range);
				}
			}

			Diagnostic.Fixit[] fixits = new Diagnostic.Fixit[d.num_fixits];

			for (uint j = 0; j < d.num_fixits; ++j)
			{
				CX.SourceRange range;
				string repl = d.get_fixit(j, out range).str();

				SourceRange r = Translator.source_range(range);

				if (r.start.file != null &&
				    r.end.file != null &&
				    r.start.file.equal(location) &&
				    r.end.file.equal(location))
				{
					clip_location(r.start);
					clip_location(r.end);

					fixits[j] = {r, repl};
				}
			}

			d_diagnostics.add(new Diagnostic(severity,
			                                 loc,
			                                 ranges.to_array(),
			                                 fixits,
			                                 d.spelling.str()));
		}

		diagnostics_updated();
	}

	private void update_semantics(CX.TranslationUnit tu)
	{
		d_semanticsMap = new HashMap<CursorWrapper, SemanticValue>(CursorWrapper.hash,
		                                                           (EqualFunc)CursorWrapper.equal);

		d_semantics.clear();

		SemanticValue.translate(tu.cursor, location, (cursor, val) => {
			d_semantics.add(val);
			d_semanticsMap[new CursorWrapper(cursor)] = val;

			Gtk.TextIter start;
			Gtk.TextIter end;

			source_range(val.range, out start, out end);

			if (Translator.is_reference(cursor))
			{
				CursorWrapper wrapper = new CursorWrapper(cursor.referenced());

				if (d_semanticsMap.has_key(wrapper))
				{
					SemanticValue rr = d_semanticsMap[wrapper];

					for (int i = 0; i < rr.num_references; ++i)
					{
						SemanticValue mr = (Gcp.C.SemanticValue)rr.reference(i);

						val.add_reference(mr);
						mr.add_reference(val);
					}

					rr.add_reference(val);
					val.add_reference(rr);
				}
			}
		});

		semantic_values_updated();
	}

	private void on_tu_update()
	{
		/* Refill the symbol browser */
		d_tu.with_translation_unit((tu) => {
			update_diagnostics(tu);
			update_semantics(tu);
		});
	}
}

}

/* vi:ex:ts=4 */
