# Testing

Automated tests use synthetic names and do not launch Find My or make network requests. Run:

```sh
bash scripts/test.sh
bash scripts/build.sh
```

## Manual matrix

Use your own iPhone. Confirm sound delivery by hearing the phone or checking its Find My alert; an accepted Accessibility action alone is insufficient.

| Scenario | Expected result | Status |
| --- | --- | --- |
| First launch without permission | Setup explains permission; sound is unavailable | Observed |
| Enable permission | Refresh becomes available, or restart guidance appears | Pending: local signing/permission mismatch under investigation |
| Refresh Devices | Device names appear; no private status labels are persisted | Pending |
| Choose one uniquely named iPhone | Selection persists locally | Pending |
| Click Play Sound | Only that iPhone receives a Find My sound request | Pending |
| Left-click menu bar icon | Same action without opening settings first | Pending |
| Right-click / Option-click | Settings, Open Find My, and Quit appear | Pending |
| Find My closed | Launches Find My and locates the same phone | Pending |
| People or Items selected | Switches to Devices before resolving a target | Pending |
| Another device details open | Dismisses known details and reselects target | Pending |
| Duplicate phone name | Stops; asks for a unique name | Unit tested; live pending |
| Phone name changes | Stops instead of selecting another device | Unit tested; live pending |
| Name contains a comma | Full details verification prevents truncated-name selection | Unit tested; live pending |
| Phone offline | Never claims the phone rang; Apple may queue the sound | Pending |
| Rapid repeated clicks | Only one operation runs at a time | Pending |
| Revoke Accessibility | Stops and explains the required permission | Pending |
| Unknown dialog / unsupported language | Stops without clicking unrelated controls | Pending |
| Relaunch PhonePing | Remembers only selected name; no automatic ping | Pending |

## Evidence discipline

Record OS and app versions and which scenarios were actually tested. Do not commit raw AX dumps, locations, serial numbers, account emails, or screenshots containing real Find My data. Tests do not establish compatibility with macOS versions that have not been exercised.
