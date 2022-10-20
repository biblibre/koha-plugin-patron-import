# Install patron-import add-on

Installing steps:  
1) Clone or upload your add-on on the server,
2) Add it in the Koha configuration file,
3) Launch the plugin installer,
4) Enable the add-on
5) Link the add-on to a configured import

##### Clone or upload your add-on on the server

Put your add-on directory in the place Koha can access it.

```bash
koha@koha:~$ cd /home/koha/lib/
koha@koha:~$ git clone https://git.biblibre.com/Add-on-patron-import/koha-plugin-example-patron-import.git
```

##### Add it in the Koha configuration file

Edit your koha-conf.xml and add a `<pluginsdir>` tag inside the `<config>` one.

```xml
<config>
  <pluginsdir>/home/koha/lib/koha-plugin-example-patron-import</pluginsdir>
```

> At this point you might need to restart some Koha services and clear cache.

##### Launch the plugin installer

Go the Koha source code and run this command:

```bash
koha@koha:~$ /home/koha/src/
koha@koha:~$ perl misc/devel/install_plugins.pl
```

You should this kinf of result if your plugin is successfully installed

```bash
Installed Example Add-on for Patron Import plugin version 1.0
All plugins successfully re-initialised
```

##### Enable the add-on

Before being used by Koha or other plugins the add-on must be enabled.  
Go to the Koha plugins home page (`cgi-bin/koha/plugins/plugins-home.pl`), find your add-on, click on `Actions` and the `Enable` button.

##### Link the add-on to a configured import

Once your add-on is installed and enabled, you should see it when editing an import configuration.  
Here appear all the enabled plugins that implement at least one parton-import hooks.  
Just select the add-on(s) you want be used with the import.
