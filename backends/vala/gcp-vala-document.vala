using Gtk, Vala;
 
namespace Gcp.Vala{
  public class Diagnostic : Report {
    private Gcp.Vala.Document doc;
    private Gcp.SourceIndex diags;
  
    public Diagnostic(Gcp.Vala.Document doc, Gcp.SourceIndex diags){
      this.doc = doc;
      this.diags = diags;
    }
    
    public void diags_report(SourceReference? source, string message, Gcp.Diagnostic.Severity severity){
      Gcp.SourceLocation loc, loc_end;
      SourceRange[] s_range;
      Gcp.Diagnostic.Fixit[] fixit;
      
      if (!enable_warnings) { return; }
      if (source != null){

        string? filename = source.file.filename;
File? sfile = filename != null ? File.new_for_path(filename) : null;

        loc = new Gcp.SourceLocation(sfile, source.begin.line, source.begin.column);
        loc_end = new Gcp.SourceLocation(sfile, source.end.line, source.end.column);
        s_range = new Gcp.SourceRange[] { new SourceRange(loc, loc_end)};
        fixit = new Gcp.Diagnostic.Fixit[] {};
        this.diags.add(new Gcp.Diagnostic(severity,
                                         loc,
                                         s_range,
                                         fixit,
                                         message));
      }
    }
    
    public override void err (SourceReference? source, string message) {
      diags_report(source, message, Gcp.Diagnostic.Severity.ERROR);
    }
    
    public override void warn (SourceReference? source, string message) {
      diags_report(source, message, Gcp.Diagnostic.Severity.WARNING);
    }
    
    public override void depr (SourceReference? source, string message) {
      diags_report(source, message, Gcp.Diagnostic.Severity.WARNING);
    }
    
    public override void note (SourceReference? source, string message) {
      diags_report(source, message, Gcp.Diagnostic.Severity.INFO);
    }
  }
  
  public class Document: Gcp.Document, Gcp.DiagnosticSupport{
    private SourceIndex d_diagnostics;
    private Mutex d_diagnosticsLock;
    private Mutex clock;
    private uint reparse_timeout;
    private DiagnosticTags d_tags;
    private uint idle_finish;
    private bool cancelled;
    
    public Document(Gedit.Document document){
		  Object(document: document);
	  }
	  
	  construct{
	    this.d_diagnostics = new SourceIndex();
	    this.d_diagnosticsLock = new Mutex();
	    this.clock = new Mutex();
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
	    if (this.reparse_timeout != 0){
	      Source.remove(this.reparse_timeout);
	    }
	    
	    cancel();
	    
	    this.reparse_timeout = Timeout.add(300, () => {this.reparse_timeout = 0; on_reparse_timeout(); return false;});		  
	  }
	  
	  public void cancel(){
	    this.clock.lock;
	    this.cancelled = true;
	    if (this.idle_finish != 0){
	      Source.remove(this.idle_finish);
	    }
	    this.clock.unlock;
	  }
	  
	  public void update_diagnostic(Gedit.Document doc){
	    string? source_file;
	    string? source_contents;
      Gcp.SourceIndex diags;
      
      source_file = null;
      
      if (doc.location != null){
			  source_file = doc.location.get_path();
		  }
		  
		  if (source_file == null){
		    source_file = "<unknown>";
		  }
		  
		  TextIter start;
		  TextIter end;

		  doc.get_bounds(out start, out end);
		  source_contents = doc.get_text(start, end, true);
		  
		  this.clock.lock;
		  cancelled = false;
		  idle_finish = 0;
		  this.clock.unlock;
		  
		  diags = new Gcp.SourceIndex();
		  
		  CodeContext context = new CodeContext ();
      context.report = new Diagnostic(this, diags);
      CodeContext.push (context);
      
      SourceFile vala_sf = new SourceFile (context, SourceFileType.SOURCE, source_file, source_contents, true);
      context.add_source_file (vala_sf);
      
      Parser ast = new Parser();
      ast.parse(context);
      
      this.clock.lock;
      if (!this.cancelled){
		    this.idle_finish = Idle.add(() => {on_parse_finished(diags); return false;});
		  }
      this.clock.unlock; 
      CodeContext.pop();
	  }
	  
	  public void on_reparse_timeout(){
	    update_diagnostic(this.document);
	  }
	  
	  public void on_parse_finished(Gcp.SourceIndex diags){
	    this.d_diagnosticsLock.lock();
      this.d_diagnostics = diags;
      this.d_diagnosticsLock.unlock();
      diagnostics_updated();
	  }
	  
  }
}
