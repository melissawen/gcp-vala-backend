from gi.repository import GObject, Gcp
from .document import Document

class Backend(GObject.Object, Gcp.Backend):
    size = GObject.property(type=int, flags = GObject.PARAM_READABLE)

    def __init__(self):
        GObject.Object.__init__(self)

        self.documents = []
        raise Exception("Loaded!")

    def do_get_property(self, spec):
        if spec.name == 'size':
            return len(self.documents)

        GObject.Object.do_get_property(self, spec)

    def do_register_document(self, doc):
        d = Document(document=doc)
        self.documents.append(d)

        d.connect('changed', self.on_document_changed)
        return d

    def do_unregister_document(self, doc):
        doc.disconnect_by_func(self.on_document_changed)
        self.documents.remove(doc)

    def do_get(self, idx):
        return self.documents[idx]

    def on_document_changed(self, doc):
        doc.update()

# ex:ts=4:et:
