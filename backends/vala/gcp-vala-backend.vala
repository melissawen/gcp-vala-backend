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

		  Document d = doc as Document;

		  d.update();
	  }
  }
}

[ModuleInit]
public void peas_register_types (TypeModule module)
{
	Peas.ObjectModule mod = module as Peas.ObjectModule;

	mod.register_extension_type (typeof (Gcp.Backend),
	                             typeof (Gcp.Vala.Backend));
}
