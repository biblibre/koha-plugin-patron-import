# Before starting

Before configuring the plugin, here are the basic (and **important**) things that you need to draft / prepare.

#### From which source ?

CSV or LDAP

Ideally the csv must be encoded in utf8. Obligatorily the first line of the CSV must be the **column headers**.

For a LDAP import, this additional informations are needed:
* the **host and port** of the LDAP to be requested (IP address or URL),
* an authorized **account** (distinguished name) and **password** to read the directory if the anonymous bind is not allowed,
* a **search base** that is kind a sub-directory where the accounts to import are,
* a **search filter** which allow the LDAP search to select only the wanted entries,

#### Field mappings

Write a mapping table of which source fields in which Koha fields.
* name => surname,
* type => categorycode,
* etc...

If a source field is named the same way than the corresponding Koha field, the mapping is implicit and does not need to be define in the configuration page. Except if this field needs value mappings.

#### Value mappings

Define what values must be transformed before being imported into Koha and provide a transformation table for each field which needs it.
Especially for values that must correspond to an authorized value in Koha (i.e. categorycode, branchcode).

The transformation process allows "strict equals", "starts with", "contains" and regural expressions.
For very specifics matching, an add-on could do the job.

#### Matching point

One or more field(s) to be used for deduplicating patrons.
Preferably use unique fields (userid, cardnumber). It is possible to use extended attribute(s).

#### Default values (optional but recommended)

Define the default values some fields will fall back if they are empty (or invalid for categorycode and branchcode).
Defining default values for **categorycode and branchcode** should be systematic.

#### Automating

Automating is the fact of adding the import in a cronjob. This needs important informations:
* The **frequency** of the automated imports. Each hour/day/week/month ?
* The **time** of the import. Important to avoid processing during hours of use/opening.
* **Where** the CSV file will be uploaded on the server (not for LDAP).
* How the CSV file will be **named** (not for LDAP). This name could contain a date part that will be replaced with the current date when importing it (Pay attention to the import time in this case. A file could be uploaded at 11:50 pm and imported at 00:30 am the day after).
	


