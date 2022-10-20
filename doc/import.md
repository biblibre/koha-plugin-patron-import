# Create new import

To create new import, click on "New import" button on the plugin's home configuration page and fill the form elements:

* **Import name**: name of your import. Van be whatever you want.
* **Flow type**: Data source type. Only CSV is handled currently by the plugin. LDAP will coming soon
* **Create only**: If checked, add new user only. No updating.
* **Auto Cardnumber**: Let the plugin create cardnumber for your borrowers
* **Clear reports and logs older than**: Number if days import reports are kept in database. After, they are deleted

### CSV Settings

* **CSV path**: Path of the CSV file to import. If empty, you should specified it as a parameter of import command
* **Binary**:  CSV option see, [https://metacpan.org/pod/Text::CSV#binary](https://metacpan.org/pod/Text::CSV#binary)
* **End of line**: CSV option, see [https://metacpan.org/pod/Text::CSV#eol](https://metacpan.org/pod/Text::CSV#eol)
* **Char separator**: CSV option, see [https://metacpan.org/pod/Text::CSV#sep_char](https://metacpan.org/pod/Text::CSV#sep_char)
* **Quote char**: CSV option, see [https://metacpan.org/pod/Text::CSV#quote_char](https://metacpan.org/pod/Text::CSV#quote_char)
* **Empty is undef**: CSV option, see [https://metacpan.org/pod/Text::CSV#empty_is_undef](https://metacpan.org/pod/Text::CSV#empty_is_undef)
* **Allow loose quotes**: CSV option, see [https://metacpan.org/pod/Text::CSV#allow_loose_quotes](https://metacpan.org/pod/Text::CSV#allow_loose_quotes)
