using Gee;

namespace Gcp.Vala{

  class Backend : Gcp.BackendImplementation{
    
    protected override Gcp.Document create_document(Gedit.Document document)
	  {
		  Document doc = new Document(document);

  		return doc;
	  }

    public override void destroy_document(Gcp.Document document)
	  {
		  base.destroy_document(document);
	  }

	  protected override void on_document_changed(Gcp.Document doc)
	  {
		  base.on_document_changed(doc);
	  }
	  
  }
}
