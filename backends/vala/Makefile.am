plugindir = $(GCP_BACKENDS_LIBS_DIR)

plugin_LTLIBRARIES = libgcpbackendvala.la

SOURCES = \
	gcp-vala-backend.vala \
	gcp-vala-document.vala

libgcpbackendvala_la_SOURCES = $(SOURCES)

libgcpbackendvala_la_CFLAGS = $(GCP_CFLAGS) $(GEDIT_CFLAGS) -I$(top_srcdir)/src -w
libgcpbackendvala_la_LDFLAGS = -module -shared -avoid-version $(GCP_LIBS)

valapkgs = 			\
	gio-2.0 		\
	gee-1.0 		\
	gcp 			\
	gtk+-3.0 		\
	gtksourceview-3.0 	\
	gedit-3.0 		\
	libpeas-1.0 		\
	config 		\
	libvala-0.22

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/src \
	--vapidir $(top_srcdir)/vapi \
	$(foreach pkg,$(valapkgs),--pkg $(pkg))

plugin_DATA = gcpbackendvala.plugin

EXTRA_DIST = \
	gcpbackendvala.plugin

GITIGNOREFILES =			\
	$(SOURCES:.vala=.c)		\
	libgcpbackendvala_la_vala.stamp

-include $(top_srcdir)/git.mk
