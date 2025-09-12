# aklrp-cityhall (modified)
Includes: Discord webhooks for submissions/approvals/denials, deny reason storage, admin filters, and debug console prints.
- Set Config.Webhook in config.lua to your Discord webhook URL.
- Use winz.sql to create fresh tables (includes deny_reason).
- If you already imported earlier winz.sql, run the SQL patch file to add deny_reason columns.

Important: ensure dependencies: qb-core, qb-target, oxmysql
