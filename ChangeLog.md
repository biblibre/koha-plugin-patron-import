ChangeLog
=========

### Version 3.1 (6 July 2026)

#### Added
- Complete action on ajax call

#### Changed
- Plugin compatibility with Koha 24.x (CSRF on all forms, Bootstrap-aligned markup, submit file launcher modal)
- Remove useless `empty_is_undef` option

#### Fixed
- Fix typo on ajax call
- Set cardnumber to NULL (instead of empty string) on patron creation when autocardnumber is "no"
- Set cardnumber to NULL (instead of empty string) on patron update when erasable and autocardnumber is "no"
- Prevent warning when patron cardnumber is undef
- Fix indefinite debarment expiration date

### Version 3.0 (16 January 2025)

#### Added
- Historical actions on patron details run
- Add filename used to import in run details
- LDAP conf settings from koha-conf file
- Modal to run import with options directly on the staff side
- Add github page for documentation

#### Changed
- Fixes around breadcrumbs and navigation (UI enhancements)
- Fixes on patron extended attributes table
- Fix in upgrade when `dry-run` column missing