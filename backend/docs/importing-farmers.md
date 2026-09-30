# Importing a Sacco's farmers

When a Sacco starts on DairyGo, its farmer register is loaded from a
spreadsheet with `dairy-cli members import`. The same command can first clear
the test farmers and milk records made while the Sacco tried the app.

## What it does

- Reads a CSV with the columns `membership_number, name, gender, phone,
  status` (any order, headings ignore case).
  - **name**: the first word is the first name, the rest the last name.
    Written as names are (`RUDIAH MUNGAYO` becomes `Rudiah Mungayo`).
  - **gender**: `M`/`F` (or `MALE`/`FEMALE`); blank is stored as `OTHER`.
  - **phone**: may be blank. `+254…`, `254…` and 9-digit numbers are written
    as `07…`/`01…`. A farmer with no phone gets no collection SMS; the app
    asks for one when the farmer is next edited.
  - **status**: `ACTIVE` or `INACTIVE` (blank is `ACTIVE`).
- Checks the whole file first and lists every problem with its line number.
  Nothing is changed while there is a problem.
- With `--replace`, first deletes **only that Sacco's**:
  - farmers, collections, sales, spoilage and transfers;
  - customers and their payments;
  - their change history, SMS log and saved request replies.

  It keeps the Sacco, its settings, its **milk prices**, its **staff**,
  roles, and the history of staff, role and Sacco changes.
- Adds the farmers and writes one audit entry on the Sacco saying what was
  imported and cleared.
- Does all of this **in one transaction**: if anything fails, nothing
  changes.
- `--dry-run` does the whole job, prints the counts, and undoes it.

Imported farmers have no next of kin. The app asks for it the next time a
farmer is edited, as it does for farmers registered before next of kin was
required.

Farmers registered later in the app or console without a membership number
continue the Sacco's own numbering: after `150` comes `151`. Numbers are
written with at least three digits, and older numbers such as `MEM-0012`
continue as `013`.

## Running it on the server

Before you start, ask the Sacco's staff to finish any milk records waiting
to be sent from their phones. Records of farmers who were deleted will be
refused.

1. **Make the CSV** on your computer from the Sacco's spreadsheet (one row
   per farmer, the five columns above). The file holds personal data:
   **never commit it to git**.
2. **Copy it to the server and into the API container**:

   ```bash
   scp maru-members.csv root@<server>:/tmp/
   ssh root@<server>
   docker cp /tmp/maru-members.csv dairy-api:/tmp/maru-members.csv
   ```

3. **Back up the database** (and keep the file until the Sacco has checked
   its farmers):

   ```bash
   docker ps --format '{{.Names}} {{.Image}}' | grep -i postgres   # the database container
   docker exec <postgres container> pg_dump -U <user> dairy_db > /root/backup-before-import-$(date +%F).sql
   ls -lh /root/backup-before-import-*.sql                          # not empty
   ```

4. **Dry run**, and read the counts:

   ```bash
   docker exec dairy-api ./dairy-cli members import --sacco <CODE> \
     --file /tmp/maru-members.csv --replace --dry-run
   ```

5. **Import**. `--confirm` must repeat the Sacco's code:

   ```bash
   docker exec dairy-api ./dairy-cli members import --sacco <CODE> \
     --file /tmp/maru-members.csv --replace --confirm <CODE>
   ```

6. **Remove the copies**:

   ```bash
   docker exec dairy-api rm /tmp/maru-members.csv
   rm /tmp/maru-members.csv
   ```

7. **In the app**:
   - check the farmer count;
   - have staff pull down to refresh the farmer list, since phones keep a
     copy of the old one for a while.

**To undo**: restore the backup with
`docker exec -i <postgres container> psql -U <user> dairy_db < /root/backup-before-import-<date>.sql`
into an empty database. Or, simpler, run the import again from a corrected
file with `--replace`.

Without `--replace`, the farmers are added to those already there. The import
is refused if a membership number in the file is already used.
