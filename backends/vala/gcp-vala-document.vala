using Gtk, Vala;
 
namespace Gcp.Vala{
  public class Diagnostic : Report {
    private ParseThread psthread;
  
    public Diagnostic(ParseThread psthread){
      this.psthread = psthread;
    }
    
    public void diags_report(SourceReference? source, string message, Gcp.Diagnostic.Severity severity){
      Gcp.SourceIndex diags;
      diags = new Gcp.SourceIndex();
      Gcp.SourceLocation loc, loc_end;
      SourceRange[] s_range;
      Gcp.Diagnostic.Fixit[] fixit;
      
      if (!enable_warnings) { return; }
      if (source != null){

        string? filename = source.file.filename;
File? sfile = filename != null ? File.new_for_path(filename) : null;

        loc = new Gcp.SourceLocation(sfile, source.begin.line, source.begin.column);
        loc_end = new Gcp.SourceLocation(sfile, source.end.line, source.end.column);
        stderr.printf("error: " +message+"\n");
        s_range = new Gcp.SourceRange[] { new SourceRange(loc, loc_end)};
        fixit = new Gcp.Diagnostic.Fixit[] {};
        diags.add(new Gcp.Diagnostic(severity,
                                         loc,
                                         s_range,
                                         fixit,
                                         message));
      }
      this.psthread.finish_in_idle(diags);
    }
    
    public override void err (SourceReference? source, string message) {
      diags_report(source, message, Gcp.Diagnostic.Severity.ERROR);
    }
  }
  
  public class ParseThread{
    private string? source_file;
    private string? source_contents;
    private uint idle_finish;
    private bool cancelled;
    private Gedit.Document doc;
    private Gcp.Vala.Document doc_vala;
    private Mutex clock;
  
    public ParseThread(Gcp.Vala.Document doc){
    
      this.source_file = null;
      this.doc = doc.document;
      this.doc_vala = doc;
      
      if (doc.location != null){
			  this.source_file = doc.location.get_path();
		  }
		  
		  if (this.source_file == null){
		    this.source_file = "<unknown>";
		  }
		  
		  TextIter start;
		  TextIter end;

		  this.doc.get_bounds(out start, out end);
		  this.source_contents = this.doc.get_text(start, end, true);
		  
		  this.clock = new Mutex();
		  this.cancelled = false;
		  this.idle_finish = 0;
    }
    
    public void cancel(){
      this.clock.lock();
      this.cancelled = true;
      if (this.idle_finish != 0){
        Source.remove(this.idle_finish);
      }
      this.clock.unlock();
    }
    
    public async void start_parse_thread(Diagnostic reporter){
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
    
    public void finish_in_idle(Gcp.SourceIndex diags){
      this.clock.lock();
      //if (!this.cancelled){
        /*this.idle_finish = Idle.add(*/this.doc_vala.on_parse_finished(diags);/*);
      }*/
      this.clock.unlock();
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
	    stderr.printf("update\n");
	    
	    if (this.reparse_timeout != 0){
	      Source.remove(this.reparse_timeout);
	    }
	    
	    if (this.reparse_thread != null){
         this.reparse_thread.cancel();
         this.reparse_thread = null;
      }
	    
	    this.reparse_timeout = Timeout.add(300, () => {this.reparse_timeout = 0; on_reparse_timeout(); return false;});		  
	  }
	  
	  public void on_reparse_timeout(){
	    this.reparse_thread = new ParseThread(this);
	    this.reporter = new Diagnostic(this.reparse_thread);
	    this.reparse_thread.start_parse_thread(this.reporter);
	  }
	  
	  public void on_parse_finished(Gcp.SourceIndex diags){
	    this.reparse_thread = null;
	    this.d_diagnosticsLock.lock();
      this.d_diagnostics = diags;
      this.d_diagnosticsLock.unlock();
      diagnostics_updated();
	  }
	  
  }

}
