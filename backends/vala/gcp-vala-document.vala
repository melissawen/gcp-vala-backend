using Gtk, Vala;

namespace Gcp.Vala{
  public class Diagnostic : Report {
    private Gcp.Vala.Document doc;
  
    public Diagnostic(Gcp.Vala.Document doc){
      this.doc = doc;
    }
    public override void err (SourceReference? source, string message) {
      Gcp.SourceIndex diags;
      diags = new Gcp.SourceIndex();
      stderr.printf("diag");
      /*Gcp.SourceLocation loc;
      
      if (!enable_warnings) { return; }
      if (source != null){
        string? filename = source.file.filename;
		    File? sfile = filename != null ? File.new_for_path(filename) : null;
		    
        loc = new Gcp.SourceLocation(sfile, source.begin.line, source.begin.column);
        diags.add(new Gcp.Diagnostic(Gcp.Diagnostic.Severity.WARNING,
                                         loc,
                                         new Gcp.SourceRange[1],
                                         new Gcp.Diagnostic.Fixit[1],
                                         message));
      }*/
      this.doc.on_parse_finished(diags);
    }
  }
  
  public class ParseThread{
    private string? source_file;
    private string? source_contents;
    private Diagnostic reporter;
    private Gedit.Document doc;
    
    public ParseThread(Gcp.Document doc, Diagnostic reporter){
      this.doc = doc.document;
      if (doc.location != null){
			  this.source_file = doc.location.get_path();
		  }
		  
		  if (this.source_file == null){
		    this.source_file = "<unknown>";
		  }
		  
		  this.reporter = reporter;
		  //this.source_file = null;
		  
		  TextIter start;
		  TextIter end;

		  this.doc.get_bounds(out start, out end);
		  this.source_contents = this.doc.get_text(start, end, true);
    }
    
    public async void start_parse_thread(){
      ThreadFunc<void *> run = () => {
        CodeContext context = new CodeContext ();
        context.report = this.reporter;
        CodeContext.push (context);
      
        SourceFile vala_sf = new SourceFile (context, SourceFileType.SOURCE, this.source_file, this.source_contents, true);
        context.add_source_file (vala_sf);
      
        Parser ast = new Parser();
        ast.parse(context);
        
        CodeContext.pop ();
        return null;
		  };
		  try
		  {
			  Thread.create<void *>(run, false);
			  yield;
		  }
		  catch{ }
    }
  }
  
  public class Document: Gcp.Document, Gcp.DiagnosticSupport{
    private SourceIndex d_diagnostics;
    private Mutex d_diagnosticsLock;
    private uint reparse_timeout;
    private DiagnosticTags d_tags;
    private Diagnostic reporter;
    private ParseThread reparse_thread;
  
    public Document(Gedit.Document document){
		  Object(document: document);
	  }
	  construct{
	    this.d_diagnostics = new SourceIndex();
	    this.d_diagnosticsLock = new Mutex();
	    this.reparse_timeout = 0;
	  }
	  
	  public DiagnosticTags get_diagnostic_tags(){
		  return this.d_tags;
	  }
	  
	  public void set_diagnostic_tags(DiagnosticTags tags){
		  this.d_tags = tags;
		}
		
		public SourceIndex begin_diagnostics(){
		  this.d_diagnosticsLock.lock();
		  return this.d_diagnostics;
	  }

	  public void end_diagnostics(){
		  this.d_diagnosticsLock.unlock();
	  }
	  
	  public void update(){
	    stderr.printf("Update\n");
	    if (this.reparse_timeout != 0){
	      Source.remove(this.reparse_timeout);
	    }
	    
	    this.reparse_timeout = Timeout.add(500, () => {this.reparse_timeout = 0; on_reparse_timeout(); return false;});		  
	  }
	  
	  public void on_reparse_timeout(){
	    stderr.printf("On reparse timeout");
	    this.reporter = new Diagnostic(this);
	    this.reparse_thread = new ParseThread(this, this.reporter);
	    this.reparse_thread.start_parse_thread.begin;
	  }
	  
	  public void on_parse_finished(Gcp.SourceIndex diags){
	    /*this.d_diagnosticsLock.lock();
      this.d_diagnostics = diags;
      this.d_diagnosticsLock.unlock();*/
      stderr.printf("On parse finished");
	  }
	   
  } 
}
