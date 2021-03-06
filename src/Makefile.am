INCLUDES =				\
	-I$(srcdir)			\
	-I$(top_srcdir)			\
	-DDATADIR=\""$(datadir)"\"

plugindir = $(GEDIT_PLUGIN_DIR)
plugin_LTLIBRARIES = libgcp.la

vala_sources = \
	gcp.vala \
	gcp-plugin.vala \
	gcp-app-activatable.vala \
	gcp-view-activatable.vala \
	gcp-source-location.vala \
	gcp-source-range.vala \
	gcp-expand-range.vala \
	gcp-source-range-support.vala \
	gcp-source-index.vala \
	gcp-view.vala \
	gcp-document.vala \
	gcp-scrollbar-marker.vala \
	gcp-backend.vala \
	gcp-backend-implementation.vala \
	gcp-backend-manager.vala \
	gcp-unsaved-file.vala \
	gcp-semantic-value.vala \
	gcp-semantic-value-support.vala \
	gcp-symbol-browser.vala \
	gcp-symbol-browser-support.vala \
	gcp-diagnostic.vala \
	gcp-diagnostic-colors.vala \
	gcp-diagnostic-tags.vala \
	gcp-diagnostic-support.vala \
	gcp-diagnostic-message.vala \
	gcp-log.vala

SOURCES = \
	$(vala_sources) \
	gcp-utils-c.c

BUILT_SOURCES = \
	gcp.vapi \
	gcp.h

NOINSTHFILES = \
	gcp-utils-c.h

EXTRA_DIST = $(NOINSTHFILES)

libgcp_la_SOURCES = $(SOURCES)

libgcp_la_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--header gcp.h \
	--vapi gcp.vapi \
	--library libgcp \
	--gir Gcp-3.0.gir \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg gcp-utils \
	--pkg gtk+-3.0 \
	--pkg gtksourceview-3.0 \
	--pkg gedit-3.0 \
	--pkg libpeas-1.0 \
	--pkg gobject-introspection-1.0 \
	--pkg posix \
	--pkg config

libgcp_la_CFLAGS = $(GCP_CFLAGS) $(GEDIT_CFLAGS) -I$(top_srcdir) -w
libgcp_la_LDFLAGS = -module -shared -avoid-version $(GCP_LIBS) $(GEDIT_LIBS)

INTROSPECTION_COMPILER_ARGS = --includedir $(GEDIT_GIR_DIR)

-include $(INTROSPECTION_MAKEFILE)

girdir = $(GCP_DATA_DIR)/gir-1.0
dist_gir_DATA = Gcp-3.0.gir

typelibdir = $(GCP_LIBS_DIR)/girepository-1.0
dist_typelib_DATA = $(dist_gir_DATA:.gir=.typelib)

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = 	\
	gcp.vapi	\
	gcp.deps

CLEANFILES = 				\
	libgcp_la_vala.stamp

MAINTAINERCLEANFILES = 		\
	$(dist_gir_DATA)	\
	$(dist_typelib_DATA)	\
	$(BUILT_SOURCES)

gcphdir = $(prefix)/include/gedit-$(GEDIT_API_VERSION)/gcp
gcph_HEADERS = gcp.h

GITIGNOREFILES =			\
	$(vala_sources:.vala=.c)

-include $(top_srcdir)/git.mk
