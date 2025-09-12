# aklrp-cityhall (with WINZ Food Grant)

**Features**
- Jobs tab (set non-whitelisted jobs)
- Licenses & ID purchase with cash/bank
- **WINZ Food Grant** tab for players to apply
- **WINZ Admin** tab for admins to review/approve/deny
- Approved grants pay the player bank balance (online or offline)

## Install
1. Import `winz.sql` into your database.
2. Drop this resource into your server resources folder as `aklrp-cityhall`.
3. Ensure dependencies: `qb-core`, `qb-target`, `oxmysql`.
4. Add `ensure aklrp-cityhall` to your server.cfg.
5. (Optional) Adjust positions/peds in `config.lua`.

## Permissions
Admins are detected via QBCore permissions: add your identifiers to the `admin` group or grant specific perms.

