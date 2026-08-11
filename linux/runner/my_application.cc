#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* host_command_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static constexpr char kDesktopHostCommandChannel[] =
    "com.trebuchetdynamics.hermes.wing/desktop_host_commands";

static void open_settings_cb(GtkMenuItem* item, gpointer user_data) {
  (void)item;
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->host_command_channel == nullptr) {
    return;
  }
  fl_method_channel_invoke_method(self->host_command_channel, "openSettings",
                                  nullptr, nullptr, nullptr, nullptr);
}

static void show_about_cb(GtkMenuItem* item, gpointer user_data) {
  (void)item;
  GtkWindow* window = GTK_WINDOW(user_data);
  gtk_show_about_dialog(
      window, "program-name", "Hermes Wing", "comments",
      "A cross-platform client for your Hermes Agent.", "logo-icon-name",
      "help-about", nullptr);
}

static void minimize_window_cb(GtkMenuItem* item, gpointer user_data) {
  (void)item;
  gtk_window_iconify(GTK_WINDOW(user_data));
}

static void toggle_maximized_window_cb(GtkMenuItem* item,
                                       gpointer user_data) {
  (void)item;
  GtkWindow* window = GTK_WINDOW(user_data);
  if (gtk_window_is_maximized(window)) {
    gtk_window_unmaximize(window);
  } else {
    gtk_window_maximize(window);
  }
}

static void toggle_fullscreen_window_cb(GtkMenuItem* item,
                                        gpointer user_data) {
  (void)item;
  GtkWindow* window = GTK_WINDOW(user_data);
  GdkWindow* native_window = gtk_widget_get_window(GTK_WIDGET(window));
  const bool is_fullscreen =
      native_window != nullptr &&
      (gdk_window_get_state(native_window) & GDK_WINDOW_STATE_FULLSCREEN) != 0;
  if (is_fullscreen) {
    gtk_window_unfullscreen(window);
  } else {
    gtk_window_fullscreen(window);
  }
}

static GtkWidget* create_application_menu(MyApplication* self,
                                          GtkWindow* window) {
  GtkWidget* menu_bar = gtk_menu_bar_new();
  GtkWidget* application_item = gtk_menu_item_new_with_label("Hermes Wing");
  GtkWidget* application_menu = gtk_menu_new();
  GtkWidget* settings_item = gtk_menu_item_new_with_label("Settings…");
  GtkWidget* separator = gtk_separator_menu_item_new();
  GtkWidget* about_item = gtk_menu_item_new_with_label("About Hermes Wing");
  GtkWidget* window_item = gtk_menu_item_new_with_label("Window");
  GtkWidget* window_menu = gtk_menu_new();
  GtkWidget* minimize_item = gtk_menu_item_new_with_label("Minimize");
  GtkWidget* maximize_item =
      gtk_menu_item_new_with_label("Maximize / Restore");
  GtkWidget* view_item = gtk_menu_item_new_with_label("View");
  GtkWidget* view_menu = gtk_menu_new();
  GtkWidget* fullscreen_item = gtk_menu_item_new_with_label("Full Screen");

  GtkAccelGroup* accelerators = gtk_accel_group_new();
  gtk_window_add_accel_group(window, accelerators);
  gtk_widget_add_accelerator(settings_item, "activate", accelerators,
                             GDK_KEY_comma, GDK_CONTROL_MASK,
                             GTK_ACCEL_VISIBLE);
  gtk_widget_add_accelerator(fullscreen_item, "activate", accelerators,
                             GDK_KEY_F11, static_cast<GdkModifierType>(0),
                             GTK_ACCEL_VISIBLE);
  g_object_unref(accelerators);

  g_signal_connect(settings_item, "activate", G_CALLBACK(open_settings_cb),
                   self);
  g_signal_connect(about_item, "activate", G_CALLBACK(show_about_cb), window);
  gtk_menu_shell_append(GTK_MENU_SHELL(application_menu), settings_item);
  gtk_menu_shell_append(GTK_MENU_SHELL(application_menu), separator);
  gtk_menu_shell_append(GTK_MENU_SHELL(application_menu), about_item);
  gtk_menu_item_set_submenu(GTK_MENU_ITEM(application_item), application_menu);

  g_signal_connect(minimize_item, "activate", G_CALLBACK(minimize_window_cb),
                   window);
  g_signal_connect(maximize_item, "activate",
                   G_CALLBACK(toggle_maximized_window_cb), window);
  gtk_menu_shell_append(GTK_MENU_SHELL(window_menu), minimize_item);
  gtk_menu_shell_append(GTK_MENU_SHELL(window_menu), maximize_item);
  gtk_menu_item_set_submenu(GTK_MENU_ITEM(window_item), window_menu);

  g_signal_connect(fullscreen_item, "activate",
                   G_CALLBACK(toggle_fullscreen_window_cb), window);
  gtk_menu_shell_append(GTK_MENU_SHELL(view_menu), fullscreen_item);
  gtk_menu_item_set_submenu(GTK_MENU_ITEM(view_item), view_menu);

  gtk_menu_shell_append(GTK_MENU_SHELL(menu_bar), application_item);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu_bar), window_item);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu_bar), view_item);
  return menu_bar;
}

static void create_host_command_channel(MyApplication* self, FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->host_command_channel = fl_method_channel_new(
      messenger, kDesktopHostCommandChannel, FL_METHOD_CODEC(codec));
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Hermes Wing");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Hermes Wing");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_set_size_request(GTK_WIDGET(window), 360, 480);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));

  GtkWidget* application_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  GtkWidget* application_menu = create_application_menu(self, window);
  gtk_box_pack_start(GTK_BOX(application_box), application_menu, FALSE, FALSE,
                     0);
  gtk_box_pack_start(GTK_BOX(application_box), GTK_WIDGET(view), TRUE, TRUE, 0);
  gtk_widget_show_all(application_box);
  gtk_container_add(GTK_CONTAINER(window), application_box);

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  create_host_command_channel(self, view);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->host_command_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
