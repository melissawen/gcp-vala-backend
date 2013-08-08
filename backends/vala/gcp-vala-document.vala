using Gtk, Vala;

namespace Gcp.Vala{
  public class Diagnostic : Report {
    public weak GtkSource.View source_view { private set; get; }
    private Gcp.SourceIndex diags;
    private Gcp.SourceLocation loc;
    
    public Diagnostic (GtkSource.View source_view) {
      this.source_view = source_view;
    }
    
    public void set_diags(Gcp.SourceIndex diags){
      this.diags = diags;
    }
    
    public override void note (SourceReference? source, string message) {
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
      }
    }
    
    public override void depr (SourceReference? source, string message) {
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
      }
    }
    
    public override void warn (SourceReference? source, string message) {
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
      }
    }
    
    public override void err (SourceReference? source, string message) {
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
      }
    }       
  }

  public class ParseThread{
    private string? source_file;
    private string? source_contents;
    private Diagnostic reporter;
    private Gedit.Document doc;
    
    public ParseThread(Gcp.Document doc){
      this.doc = doc.document;
      if (doc.location != null){
			  this.source_file = doc.location.get_path();
		  }
		  
		  if (this.source_file == null){
		    this.source_file = "<unknown>";
		  }
		  
		  this.source_file = null;
		  
		  TextIter start;
		  TextIter end;

		  this.doc.get_bounds(out start, out end);
		  this.source_contents = this.doc.get_text(start, end, true);
    }
    
    public async void start_parse_thread(){
      ThreadFunc<void *> run = () => {
        CodeContext context = new CodeContext ();
        context.report = reporter;
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
    private DiagnosticTags d_tags;
    private SourceIndex d_diagnostics;
    private Mutex d_diagnosticsLock;
    private uint reparse_timeout;
    private ParseThread reparse_thread;
    
    public Document(Gedit.Document document){
		  Object(document: document);
	  }    
    
    construct{
	    this.d_diagnostics = new SourceIndex();
	    this.d_diagnosticsLock = new Mutex();
	    this.reparse_timeout = 0;
	  }
	  
	  public void set_diagnostic_tags(DiagnosticTags tags){
		  d_tags = tags;
		}
	 
	  public DiagnosticTags get_diagnostic_tags(){
		  return d_tags;
	  }
	  
	  public void update(){
	    if (this.reparse_timeout != 0){
	      Source.remove(this.reparse_timeout);
	    }
	    
		  this.reparse_timeout = Timeout.add(500, () => {this.reparse_timeout = 0; on_reparse_timeout(); return false;});
		  
	  }
	  
	  public SourceIndex begin_diagnostics(){
		  d_diagnosticsLock.lock();
		  return d_diagnostics;
	  }

	  public void end_diagnostics(){
		  d_diagnosticsLock.unlock();
	  }
	  
	  public void on_reparse_timeout(){
	     this.reparse_thread = new ParseThread(this);
	     this.reparse_thread.start_parse_thread();
	  }
	  
	   
	}
}
